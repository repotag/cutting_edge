require 'rubygems'
require 'json'
require 'http'

class PythonLang < Language
  COMPARATORS = />=|>|<=|<|==/
  VERSION_NUM = /\d[\.\w]*/
  SUFFIX_OPTION = /\s*(\[.*\])?/
  NAME = /[^,]+/
  REGEX = /^(#{NAME})\s*(#{COMPARATORS})\s*(#{VERSION_NUM})(\s*,\s*(#{COMPARATORS})\s*(#{VERSION_NUM}))?#{SUFFIX_OPTION}$/

  API_URL = 'https://pypi.org/pypi/'

  class << self

    # Defaults for projects in this language
    def locations(name)
      ['requirements.txt']
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
        results = parse_pipfile(content)
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
          dep = Gem::Dependency.new(name, "#{first_comp} #{first_version}")
          dep.requirement.concat(["#{second_comp} #{second_version}"]) if second_comp && second_version
        else
          dep = Gem::Dependency.new(line.strip) # requries version to be >= 0
        end
        results << dep
      end
      results
    end

    def parse_pipfile(content)
      []
    end

    # Find the latest versions of a dependency by name
    #
    # name - String name of the dependency
    #
    # Returns a Gem::Version
    def latest_version(name)
      content = HTTP.follow(max_hops: 1).get(::File.join(API_URL, name, 'json'))
      begin
        Gem::Version.new(JSON.parse(content)['info']['version'])
      rescue StandardError => e
        log_error("Encountered error when fetching latest version of #{name}: #{e.class} #{e}")
        nil
      end
    end
  end
end