require 'rubygems'
require 'json'
require 'http'

class PythonLang
  COMPARATORS = />=|>|<=|<|==/
  VERSION_NUM = /\d[\.\w]*/
  SUFFIX_OPTION = /\s*(\[.*\])?/
  NAME = /[^,]+/
  REGEX = /^(#{NAME})\s*(#{COMPARATORS})\s*(#{VERSION_NUM})(\s*,\s*(#{COMPARATORS})\s*(#{VERSION_NUM}))?#{SUFFIX_OPTION}$/

  API_URL = 'https://pypi.org/pypi/'

  # Defaults for projects in this language
  def self.locations(name)
    ['requirements.txt']
  end

  # Find the latest versions of gems in this gemspec
  #
  # content - String contents of the gemspec
  #
  # Returns an Array of tuples of each dependency and its latest version: [[<Bundler::Dependency>, <Gem::Version>]]
  def self.parse_file(name, content)
    return nil unless content
    if name =~ /\.txt$/
      self.parse_requirements(content)
    elsif name == 'Pipfile'
      self.parse_pipfile(content)
    end
  end

  def self.parse_requirements(content)
    results = []
    content.each_line do |line|
      next if line =~ /^\s*-e/ # ignore 'editable' dependencies
      if line =~ COMPARATORS
        match = line.match(REGEX)
        return nil unless match
        name, first_comp, first_version, _ignore, second_comp, second_version = match.captures
        first_comp = '=' if first_comp == '=='
        second_comp = '=' if second_comp == '=='
        dep = Gem::Dependency.new(name, "#{first_comp} #{first_version}")
        dep.requirement.concat(["#{second_comp} #{second_version}"]) if second_comp && second_version
      else
        name = line.strip
        dep = Gem::Dependency.new(name)
      end
      results << [dep, latest_version(name)]
    end
    results
  end

  def self.parse_pipfile(content)
    []
  end

  def self.latest_version(name)
    content = HTTP.follow(max_hops: 1).get(::File.join(API_URL, name, 'json'))
    begin
      Gem::Version.new(JSON.parse(content)['info']['version'])
    rescue
      nil
    end
  end
end