require 'rubygems'
require 'http'
require File.expand_path('../../versions.rb', __FILE__)
require File.expand_path('../../langs.rb', __FILE__)
require File.expand_path('../helpers.rb', __FILE__)
require 'hashdiff'

class DependencyWorker < GenericWorker
  include VersionRequirementComparator

  # Order is significant for purposes of calculating results[:outdated]
  STATUS_TYPES = [:outdated_major, :outdated_minor, :outdated_patch, :ok, :no_requirement, :unknown]
  OUTDATED_TYPES = STATUS_TYPES[0..-4] # Which types indicate an outdated dependency. Used to calculate the total number of out-of-date dependencies.
  
  def perform(identifier, lang, locations, dependency_types, to_addr, auth_token = nil)
    log_info 'Running Worker!'
    @lang = get_lang(lang)
    @provider = get_provider(identifier)
    @auth_token = auth_token
    old_dependencies = get_from_store(identifier) || {}
    begin
      dependencies = {:locations => {}}
      locations.each do |name, url|
        contents = http_get(url)
        dependencies[:locations][name] = get_results(@lang.parse_file(name, contents), dependency_types)
      end
      dependencies.merge!(generate_stats(dependencies[:locations]))
      @nothing_changed = dependencies == old_dependencies
      unless @nothing_changed
        add_to_store(identifier, dependencies)
        add_to_store("diff-#{identifier}", diff_dependencies(old_dependencies[:locations], dependencies[:locations]))
      end
    ensure
      unless @nothing_changed
        badge_worker(identifier)
        mail_worker(identifier, to_addr) if to_addr && (!old_dependencies.empty? || ::CuttingEdge::ALWAYS_MAIL)
      end
      GC.start
    end
  end

  private
  
  def diff_dependencies(old, new)
    base = old ? old : new.transform_values {|_v| empty_status_hash }
    diff = Hashdiff.diff(base, new)
    additions = diff.select {|x| x.first == '+'}
    deletions = diff.select {|x| x.first == '-'}
    result = {}
    
    additions.each do |addition|
      status = parse_diff_status(addition[1])
      name = addition.last[:name]
      old_status = deletions.find {|x| x.last[:name] == name}
      old_status = parse_diff_status(old_status[1]) if old_status
      result[name] = change_type(old_status, status)
    end
    result
  end
  
  def parse_diff_status(str)
    # Hashdiff generates strings of the form "gemfile.ok[1]" to indicate this is the first change to the Hash under the :ok key
    str.split('.').last.split('[').first.to_sym
  end
  
  def change_type(old_status, new_status)
    case
    when new_status == :ok
      :good_change
    when outdated_type?(new_status) && old_status && STATUS_TYPES.find_index(new_status) > STATUS_TYPES.find_index(old_status)
      :good_change
    else
      :bad_change
    end
  end
  
  def empty_status_hash
    Hash[STATUS_TYPES.map {|status| [status, []]}]
  end
  
  def get_results(dependencies, dependency_types)
    results = empty_status_hash
    if dependencies
      dependencies.select! {|dep| dependency_types.include?(dep.first.type)}
      dependencies.each do |dep, latest_version|
        dependency_hash = dependency(dep.name, dep.requirement.to_s, latest_version.to_s, dep.type)
        if dependency_hash[:required] == 'unknown'
          results[:no_requirement] << dependency_hash
        elsif latest_version.nil?
          results[:unknown] << dependency_hash
        elsif is_outdated?(dep, latest_version)
          outdated = version_requirement_diff(dep.requirement, latest_version.respond_to?(:last) ? latest_version.last : latest_version)
          results[outdated] << dependency_hash
        else
          results[:ok] << dependency_hash
        end 
      end
    end
    results
  end

  def generate_stats(locations)
    results = {}
    STATUS_TYPES.each do |type|
      num = stats(type, locations)
      results[type] = num
      if outdated_type?(type)
        results[:outdated_total] = results[:outdated_total].to_i + num
        results[:outdated] = type unless results[:outdated] || num == 0
      end
    end
    results[:outdated] = :unknown if results[:outdated_total] == 0 && results[:ok] == 0
    results[:outdated] = :up_to_date unless results[:outdated]
    results
  end
  
  # Add up the number of dependencies of type `stat` (e.g. :ok) in the different locations where dependencies are stored.
  def stats(stat, locations)
    sum = 0
    locations.each do |name, dependencies|
      sum = sum + dependencies[stat].length
    end
    sum
  end

  def dependency(name, requirement, latest, type)
    {
      :name => name,
      :required => requirement,
      :latest => latest,
      :type => type,
      :url => requirement == 'unknown' ? nil : @lang.website(name)
    }
  end

  def get_lang(lang)
    Object.const_get("#{lang.capitalize}Lang")
  end
  
  def get_provider(identifier)
    ::CuttingEdge.const_get("#{identifier.split('/').first.capitalize}Repository")
  end

  def http_get(url)
    begin
      response = HTTP.headers(@provider.headers(@auth_token)).get(url)
      response.status == 200 ? response.to_s : nil
    rescue HTTP::TimeoutError => e
      log_info("Encountered error when fetching latest version of #{url}: #{e.class} #{e.message}")
    end
  end

  def is_outdated?(dependency, latest_version)
    !dependency.requirement.satisfied_by?(latest_version)
  end
  
  def outdated_type?(type)
    OUTDATED_TYPES.include?(type)
  end
end