require 'ostruct'
require 'sinatra/logger'

module LanguageHelpers
  # Return a mock construct that mimicks Gem::Dependency for depedencies we tried to parse, but weren't valid.
  def unknown_dependency(name, type = :runtime)
    OpenStruct.new(name: name, type: type, requirement: 'unknown')
  end

  # For each dependency, find its latest version and return the two together. Takes account of invalid or dependencies (see #unknown_dependency)
  #
  # results - Array of Gem::Dependencies and unknown dependencies.
  #
  # Returns an Array of tuples of each dependency and its latest version: e.g., [[<Gem::Dependency>, <Gem::Version>]]
  def dependency_with_latest(results)
    results.map do |dependency|
      [dependency, dependency.requirement.to_s == 'unknown' ? nil : latest_version(dependency.name)]
    end
  end

  def log_error(message)
    logger.error(message) if defined?(::RubyDeps) && ::RubyDeps.enable_logging
  end
end

class Language
  include ::SemanticLogger::Loggable
  extend LanguageHelpers
end

module LanguageHelpers
  private

  # Translate version requirement syntax to a String or Array of Strings that Gem::Dependency.new understands
  # See https://www.python.org/dev/peps/pep-0440/#version-matching
  def translate_requirement(req, language)
    if language == :python
      req.sub!('~=', '~>')
      req.sub!('==', '=')
    elsif language == :rust
      req.sub!('~', '~>')
      req = "^#{req}" unless req =~ /~|<|>|\*|\^|=/ # No comparators means caret requirement
    end

    case req
    when /\^/
      # ^1.2.3  :=  >=1.2.3, <2.0.0
      # ^1.2    :=  >=1.2.0, <2.0.0
      # ^1      :=  >=1.0.0, <2.0.0
      # ^0.2.3  :=  >=0.2.3, <0.3.0
      # ^0.2    :=  >=0.2.0, <0.3.0
      # ^0.0.3  :=  >=0.0.3, <0.0.4
      # ^0.0    :=  >=0.0.0, <0.1.0
      # ^0      :=  >=0.0.0, <1.0.0
      # upper bound = take the left most non-zero digit and +1 it
      req.sub!('^', '')
      version = Gem::Version.new(req)
      segments = version.version.split('.')
      left_non_zero = segments.find_index {|seg| seg > 0} || segments.rindex {|seg| seg == 0} # Find the leftmost non-zero digit. If there is none, find the last 0.
      segments[left_non_zero] += 1
      upper_bound = segments.join('.')
      [">= #{version.version}", "< #{upper_bound}"]
    when '*'
      '>= 0'
    when /\.\*/
      if req =~ /!=/
        # Turn != 1.1.* into >= 1.2, < 1.1
        req.sub!('.*', '.0')
        req.sub!('!=', '')
        v = Gem::Version.new(req) # Create the bumped version using Gem::Version so pre-release handing will work
        lower_bound = ">= #{v.bump.version}"
        upper_bound = "< #{v.version}"
        [lower_bound, upper_bound]
      else
        # Turn =1.1.* into ~> 1.1.0
        req.sub!('=', '~>')
        req.sub!('.*', '.0')
        req
      end
    else
      req
    end
  end

  def parse_toml(content, sections, language)
    begin
      config = TomlRB.parse(content)
    rescue TomlRB::ParseError => e
      log_error("Encountered error when parsing TOML: #{e.class} #{e.message}")
      return []
    end    
    results = []

    sections.each do |dependency_type, section_name|
      packages = config[section_name] || next
      packages.each do |name, info|
        requirement = info.fetch('version', nil) rescue info
        if requirement
          requirements = requirement.split(',').map {|req| translate_requirement(req, language)}
          begin
            results << Gem::Dependency.new(name, requirements, dependency_type)
          rescue StandardError => e
            log_error("Encountered error when parsing requirement #{requirements}: #{e.class} #{e.message}")             
            next
          end
        else
          results << unknown_dependency(name, dependency_type)
        end
      end
    end
    results
  end

end

Dir[File.expand_path('../langs/*.rb', __FILE__)].each { |f| require f }