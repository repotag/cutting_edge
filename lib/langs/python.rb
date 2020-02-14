class PythonLang

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
    puts "Got for PythonLang.parse_file:"
    puts content.inspect
    []
  end

  def self.latest_version(name)
  end
end