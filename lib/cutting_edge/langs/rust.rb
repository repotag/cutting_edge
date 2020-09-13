require 'rubygems'
require 'http'

class RustLang < Language
  API_URL = 'https://crates.io/api/v1/crates'

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
    
    def website(name)
      "https://crates.io/crates/#{name}"
    end

    # Parse a dependency file
    #
    # name - String contents of the file
    # content - String contents of the file
    #
    # Returns an Array of tuples of each dependency and its latest version: [[<Gem::Dependency>, <Gem::Version>]]
    def parse_file(name, content)
      return nil unless content
      results = parse_toml(content, CARGOFILE_SECTIONS)
      dependency_with_latest(results) if results
    end

    # Find the latest versions of a dependency by name
    #
    # name - String name of the dependency
    #
    # Returns a Gem::Version
    def latest_version(name)
      begin
        content = HTTP.timeout(::CuttingEdge::LAST_VERSION_TIMEOUT).get(::File.join(API_URL, name)).parse
        version = content['crate']['max_version']
        Gem::Version.new(canonical_version(version))
      rescue StandardError, HTTP::Error => e
        log_error("Encountered error when fetching latest version of #{name}: #{e.class} #{e.message}")
        nil
      end      
    end

    # Translate Cargo version requirement syntax to a String or Array of Strings that Gem::Dependency.new understands
    # Cargo.toml files support * and ^ (wildcard and caret) requirements, which Ruby does not
    # See: https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html
    # 
    # req - String version requirement
    #
    # Returns a translated String version requirement
    def translate_requirement(req)
      if req =~ /~|<|>|\*|=/
        return translate_wildcard(req) if req =~ /\*/
        req.sub!('~', '~>')
        req
      else
        translate_caret(req)
      end
    end

  end
end