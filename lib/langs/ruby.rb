require 'gemnasium/parser'
require 'rubygems'

class RubyLang

  # Defaults for projects in this language
  def self.locations(name)
    ["#{name}.gemspec", 'Gemfile']
  end

  # Find the latest versions of gems in this gemspec
  #
  # content - String contents of the gemspec
  #
  # Returns an Array of tuples of each dependency and its latest version: [[<Bundler::Dependency>, <Gem::Version>]]
  def self.parse_file(name, content)
    return nil unless content
    if name =~ /gemspec/
      parse_gemspec(content)
    else
      parse_gemfile(content)
    end
  end

  def self.latest_version(name)
    # Fancy todo: cache these?
    Gem::SpecFetcher.fetcher.spec_for_dependency(Gem::Dependency.new(name, nil)).flatten.first
  end

  def self.parse_ruby(type, content)
    Gemnasium::Parser.send(type, content).dependencies.map do |dep|
      [dep, latest_version(dep.name).version]
    end
  end

  def self.parse_gemspec(content)
    parse_ruby(:gemspec, content)
  end

  def self.parse_gemfile(content)
    parse_ruby(:gemfile, content)
  end
end