require 'rubygems'
require 'http'
require 'moneta'
require File.expand_path('../../versions.rb', __FILE__)
require File.expand_path('../../langs.rb', __FILE__)
require File.expand_path('../helpers.rb', __FILE__)

class DependencyWorker < GenericWorker
  include VersionRequirementComparator

  # Order is significant for purposes of calculating results[:outdated]
  STATUS_TYPES = [:outdated_major, :outdated_minor, :outdated_bump, :ok, :unknown]
  OUTDATED_TYPES = STATUS_TYPES[0..-3]

  def perform(identifier, lang, locations, dependency_types)
    log_info 'Running Worker!'
    @dependency_types = dependency_types
    @lang = get_lang(lang)
    dependencies = {}
    locations.each do |name, url|
      contents = http_get(url)
      dependencies[name] = get_results(@lang.parse_file(name, contents))
    end
    dependencies.merge!(generate_stats(dependencies))
    add_to_store(identifier, dependencies)
    GC.start
  end

  private

  def get_results(dependencies)
    results = {}
    STATUS_TYPES.each {|type| results[type] = []}
    if dependencies
      dependencies.select! {|dep| @dependency_types.include?(dep.first.type)}
      dependencies.each do |dep, latest_version|
        dependency_hash = dependency(dep.name, dep.requirement.to_s, latest_version.to_s, dep.type)
        if latest_version.nil? || dependency_hash[:required] == 'unknown'
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
      if OUTDATED_TYPES.include?(type)
        results[:outdated_total] = results[:outdated_total].to_i + num
        results[:outdated] = type unless results[:outdated] || num == 0
      end
    end
    results[:outdated] = :unknown if results[:outdated_total] == 0 && results[:ok] == 0
    results[:outdated] = :up_to_date unless results[:outdated]
    results
  end

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
      :type => type
    }
  end

  def get_lang(lang)
    Object.const_get("#{lang.capitalize}Lang")
  end

  def http_get(url)
    # TODO: timeouts and exceptions
    HTTP.get(url).to_s 
  end

  def is_outdated?(dependency, latest_version)
    !dependency.requirement.satisfied_by?(latest_version)
  end

end