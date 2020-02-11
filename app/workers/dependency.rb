require 'gemnasium/parser'
require 'rubygems'
require 'http'
require 'sidekiq'

class DependencyWorker
  include Sidekiq::Woker

  def perform(gemspec_url, gemfile_url)
    @dependencies = []
    @dependencies = @dependencies + gemspec(gemspec_url) if gemspec_url
    @dependencies = @dependencies + gemspec(gemspec_url) if gemfile_url
    puts @dependencies.inspect
  end

  private

  def gemfile(url)
    parse(:gemfile, http_get(url))
  end

  def gemspec(url)
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
    Gem::SpecFetcher.fetcher.spec_for_dependency(Gem::Dependency.new(gem_name, nil)).flatten.first
  end

  def is_outdated?(dependency, latest_version)
    !dependency.requirement.satisfied_by?(latest_version)
  end

end