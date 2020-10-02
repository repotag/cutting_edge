require 'rubygems'
require 'http'

class PythonLang < Language
  # For Requirements.txt
  # See https://iscompatible.readthedocs.io/en/latest/
  COMPARATORS = />=|>|<=|<|==/
  VERSION_NUM = /\d[\.\w]*/
  SUFFIX_OPTION = /\s*(\[.*\])?/
  NAME = /[^,]+/
  REGEX = /^(#{NAME})\s*(#{COMPARATORS})\s*(#{VERSION_NUM})(\s*,\s*(#{COMPARATORS})\s*(#{VERSION_NUM}))?#{SUFFIX_OPTION}$/

  API_URL = 'https://pypi.org/pypi/'

  PIPFILE_SECTIONS = {
    :runtime => 'packages',
    :development => 'dev-packages'
  }

  extend LanguageVersionHelpers

  class << self

    # Defaults for projects in this language
    def locations(name = nil)
      ['requirements.txt', 'Pipfile']
    end
    
    def website(name)
      "https://pypi.org/project/#{name}"
    end

    # Parse a dependency file
    #
    # name - String contents of the file
    # content - String contents of the file
    #
    # Returns an Array of tuples of each dependency and its latest version: [[<Gem::Dependency>, <Gem::Version>]]
    def parse_file(name, content)
      return nil unless content
      if name =~ /\.txt$/
        results = parse_requirements(content)
      elsif name =~ /Pipfile/
        results = parse_toml(content, PIPFILE_SECTIONS)
      end
      dependency_with_latest(results) if results
    end

    def parse_requirements(content)
      results = []
      content.each_line do |line|
        next if line =~ /^\s*-e/ # ignore 'editable' dependencies
        if line =~ COMPARATORS
          next unless match = line.match(REGEX) # Skip this line if it doesn't conform to our expectations
          name, first_comp, first_version, _ignore, second_comp, second_version = match.captures
          first_comp = '=' if first_comp == '=='
          second_comp = '=' if second_comp == '=='
          dep = Gem::Dependency.new(name.strip, "#{first_comp} #{first_version}")
          dep.requirement.concat(["#{second_comp} #{second_version}"]) if second_comp && second_version
        else
          dep = Gem::Dependency.new(line.strip) # requries version to be >= 0
        end
        results << dep
      end
      results
    end

    # Find the latest versions of a dependency by name
    #
    # name - String name of the dependency
    #
    # Returns a Gem::Version
    def latest_version(name)
      begin
        content = HTTP.timeout(::CuttingEdge::LAST_VERSION_TIMEOUT).follow(max_hops: 1).get(::File.join(API_URL, name, 'json')).parse
        version = content['info']['version']
        Gem::Version.new(canonical_version(version))
      rescue StandardError, HTTP::TimeoutError => e
        log_error("Encountered error when fetching latest version of #{name}: #{e.class} #{e.message}")
        nil
      end
    end

    # Translate version requirement syntax for Pipfiles to a String or Array of Strings that Gem::Dependency.new understands
    # Pipfile support * and != requirements, which Ruby does not
    # See https://www.python.org/dev/peps/pep-0440/#version-matching
    # 
    # req - String version requirement
    #
    # Returns a translated String version requirement
    def translate_requirement(req)
    req.sub!('~=', '~>')
    req.sub!('==', '=')
      case req
      when /\*/
        translate_wildcard(req)
      when '!='
        req.sub!('!=', '')
        ["< #{req}", "> #{req}"]
      else
        req
      end
    end

  end
end