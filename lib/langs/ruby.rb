require 'gemnasium/parser'
require 'rubygems'

class RubyLang < Language

  class << self

    # Defaults for projects in this language
    def locations(name)
      ["#{name}.gemspec", 'Gemfile']
    end

    # Parse a dependency file
    #
    # name - String contents of the file
    # content - String contents of the file
    #
    # Returns an Array of tuples of each dependency and its latest version: [[<Bundler::Dependency>, <Gem::Version>]]
    def parse_file(name, content)
      return nil unless content
      results = name =~ /gemspec/ ? parse_gemspec(content) : parse_gemfile(content)
      dependency_with_latest(results)
    end

    def latest_version(name)
      # Fancy todo: cache these?
      begin
        Gem::SpecFetcher.fetcher.spec_for_dependency(Gem::Dependency.new(name, nil)).flatten.first.version
      rescue StandardError => e
        log_error("Encountered error when fetching latest version of #{name}: #{e.class} #{e.message}")
        nil
      end
    end

    def parse_ruby(type, content)
      Gemnasium::Parser.send(type, content).dependencies
    end

    def parse_gemspec(content)
      parse_ruby(:gemspec, content)
    end

    def parse_gemfile(content)
      parse_ruby(:gemfile, content)
    end
  end
end