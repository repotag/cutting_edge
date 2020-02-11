require 'gemnasium/parser'
require 'rubygems'
require 'http'
require 'sidekiq'
require 'json'
require 'redis-objects'
require File.expand_path('../../versions.rb', __FILE__)

class DependencyWorker
  include Sidekiq::Worker
  include VersionRequirementComparator

  def perform(identifier, gemspec_url, gemfile_url)
    gemspec_deps = gemspec(gemspec_url)
    gemfile_deps = gemfile(gemfile_url)
    gemspec_results = get_results(gemspec_deps)
    gemfile_results = get_results(gemfile_deps)
    add_to_redis(identifier, {:gemspec => gemspec_results, :gemfile => gemfile_results})
  end

  private

  def get_results(dependencies)
    if dependencies
      results = {:outdated_major => [],  :outdated_minor => [], :outdated_bump => [], :ok => []}
      dependencies.each do |dep, latest_version|
        dependency_hash = dependency(dep.name, dep.requirement.to_s, latest_version.to_s)
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

  def dependency(name, requirement, latest)
    {
      :name => name,
      :required => requirement,
      :latest => latest
    }
  end

  def add_to_redis(identifier, dependencies)
    Sidekiq.redis do |connection|
      Redis::Objects.redis = connection
      store = Redis::Value.new(identifier)
      store.value = dependencies.to_json
    end
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