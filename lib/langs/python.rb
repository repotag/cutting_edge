require 'rubygems'
require 'json'
require 'http'

class PythonLang
  COMPARATORS = />=|>|<=|<|==/
  VERSION_NUM = /\d[^,]*/
  REGEX = /^([^,]+)\s*(#{COMPARATORS})\s*(#{VERSION_NUM})(\s*,\s*(#{COMPARATORS})\s*(#{VERSION_NUM}))?$/

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
    results = []
    content.each_line do |line|
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
      latest = latest_version(name)
      results << [dep, latest]
    end
    results
  end

  def self.latest_version(name)
    content = HTTP.follow(max_hops: 1).get(::File.join(API_URL, name, 'json'))
    if content
      json = JSON.parse(content)
      Gem::Version.new(json['info']['version']) if json['info']['version']
    else
      nil # Todo: error handling, timeouts
    end
  end
end