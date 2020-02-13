require 'gemnasium/parser'
require 'rubygems'
require 'http'
require 'sucker_punch'
require 'sinatra/logger'
require 'moneta'
require File.expand_path('../../versions.rb', __FILE__)

class DependencyWorker
  include SuckerPunch::Job
  include VersionRequirementComparator
  include ::SemanticLogger::Loggable

  def perform(identifier, gemspec_url, gemfile_url, dependency_types)
    log_info "Running Worker!"
    @dependency_types = dependency_types
    gemspec_deps = gemspec(gemspec_url)
    gemfile_deps = gemfile(gemfile_url)
    gemspec_results = get_results(gemspec_deps)
    gemfile_results = get_results(gemfile_deps)
    add_to_store(identifier, {:gemspec => gemspec_results, :gemfile => gemfile_results})
    GC.start
  end

  private

  def log_info(message)
    logger.info(message) if ::RubyDeps.enable_logging
  end

  def get_results(dependencies)
    if dependencies
      dependencies.select! {|dep| @dependency_types.include?(dep.first.type)} # dependency_types is passed as an Array of symbols, but this gets translated by Sidekiq to an Array of Strings.
      results = {:outdated_major => [],  :outdated_minor => [], :outdated_bump => [], :ok => [], :unknown => []}
      dependencies.each do |dep, latest_version|
        dependency_hash = dependency(dep.name, dep.requirement.to_s, latest_version.to_s, dep.type)
        if is_outdated?(dep, latest_version)
          outdated = version_requirement_diff(dep.requirement, latest_version.respond_to?(:last) ? latest_version.last : latest_version)
          results[outdated] << dependency_hash
        else
          results[:ok] << dependency_hash
        end 
      end
      results
    else
      []
    end
  end

  def dependency(name, requirement, latest, type)
    {
      :name => name,
      :required => requirement,
      :latest => latest,
      :type => type
    }
  end

  def add_to_store(identifier, dependencies)
    ::RubyDeps.store[identifier] = dependencies
  end

  def gemfile(url)
    return nil unless url
    parse(:gemfile, http_get(url))
  end

  def gemspec(url)
    return nil unless url
    parse(:gemspec, http_get(url))
  end

  def http_get(url)
    # TODO: timeouts and exceptions
    HTTP.get(url).to_s 
  end

  # Find the latest versions of gems in this gemspec
  #
  # content - String contents of the gemspec
  #
  # Returns an Array of tuples of each dependency and its latest version: [[<Bundler::Dependency>, <Gem::Version>]]
  def parse(type, content)
    Gemnasium::Parser.send(type, content).dependencies.map do |dep|
      [dep, latest_version_spec(dep.name).version]
    end
  end

  def latest_version_spec(gem_name)
    # Fancy todo: cache these in Redis
    Gem::SpecFetcher.fetcher.spec_for_dependency(Gem::Dependency.new(gem_name, nil)).flatten.first
  end

  def is_outdated?(dependency, latest_version)
    !dependency.requirement.satisfied_by?(latest_version)
  end

end