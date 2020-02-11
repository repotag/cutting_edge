require 'gemnasium/parser'
require 'rubygems'
require 'http'
require 'sidekiq'
require 'json'
require 'redis-objects'

class DependencyWorker
  include Sidekiq::Worker

  def perform(identifier, gemspec_url, gemfile_url, source = :github)
    gemspec_deps = gemspec(gemspec_url)
    gemfile_deps = gemfile(gemfile_url)
    gemspec_results = get_results(gemspec_deps)
    gemfile_results = get_results(gemfile_deps)
    add_to_redis(source, identifier, {:gemspec => gemspec_results, :gemfile => gemfile_results})
  end

  private

  def get_results(dependencies)
    if dependencies
      results = {:outdated_major => [],  :outdated_minor => [], :outdated_bump => [], :ok => []}
      dependencies.each do |dep, latest_version|
        dependency_hash = dependency(dep.name, dep.requirement.to_s, latest_version.to_s)
        if is_outdated?(dep, latest_version)
          outdated = calculate_version_difference(dep, latest_version.respond_to?(:last) ? latest_version.last : latest_version)
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

  def add_to_redis(source, identifier, dependencies)
    Sidekiq.redis do |connection|
      Redis::Objects.redis = connection
      gem_list = Redis::HashKey.new(source.to_s)
      gem_list[identifier] = dependencies.to_json
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

  def calculate_version_difference(dependency, latest_version)
    if dependency.requirement.requirements.first.first == '='
      current_version = dependency.requirement.requirements.first.last
    else
      current_version = Gem::SpecFetcher.fetcher.search_for_dependency(dependency).first.first.first.version
    end

    current_segments = current_version.canonical_segments
    latest_segments  = latest_version.canonical_segments

    if latest_segments[0].to_i > current_segments[0].to_i
      return :outdated_major
    elsif latest_segments[1].to_i > current_segments[1].to_i
      return :outdated_minor
    else
      return :outdated_bump
    end
  end
end