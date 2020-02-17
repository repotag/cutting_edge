require 'rubygems'
require 'json'
require 'http'

class RustLang < Language
  API_URL = 'https://crates.io/api/v1/crates/'

  CARGOFILE_SECTIONS = {
    :runtime => 'dependencies',
    :development => 'dev-dependencies',
    :build => 'build-dependencies'
  }

  extend LanguageVersionHelpers

  class << self

    # Defaults for projects in this language
    def locations(name = nil)
      ['Cargo.toml']
    end

    # Parse a dependency file
    #
    # name - String contents of the file
    # content - String contents of the file
    #
    # Returns an Array of tuples of each dependency and its latest version: [[<Gem::Dependency>, <Gem::Version>]]
    def parse_file(name, content)
      return nil unless content
      results = parse_toml(content, CARGOFILE_SECTIONS, :rust)
      dependency_with_latest(results) if results
    end

    # Find the latest versions of a dependency by name
    #
    # name - String name of the dependency
    #
    # Returns a Gem::Version
    def latest_version(name)
      content = HTTP.follow(max_hops: 1).get(::File.join(API_URL, name))
      begin
        version = JSON.parse(content)['crate']['max_version']
        Gem::Version.new(canonical_version(version))
      rescue StandardError => e
        log_error("Encountered error when fetching latest version of #{name}: #{e.class} #{e.message}")
        nil
      end
    end

  end
end