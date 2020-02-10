require 'gemnasium/parser'
require 'rubygems'
require 'httparty'
require 'benchmark'

def api_latest_version_spec(gem_name)
  response = HTTParty.get("https://rubygems.org/api/v1/versions/#{gem_name}/latest.json").parsed_response
  Gem::Specification.new do |spec|
    spec.name = gem_name
    spec.version = response['version']
  end
end

def latest_version_spec(gem_name)
  Gem::SpecFetcher.fetcher.spec_for_dependency(Gem::Dependency.new(gem_name, nil)).flatten.first
end

content = <<EOF
gem 'rake', '>= 10.0', '< 14.0'
gem 'gollum', '>= 2.0', '< 4.0'
EOF
gemfile ||= Gemnasium::Parser.gemfile(content)
dependencies = gemfile.dependencies

puts "First trying with Gem::SpecFetcher\n"

dependencies.each do |dep|
  puts "Checking dependencies status for #{dep.name}"
  puts "Current required version of #{dep.name}: #{dep.requirement.to_s}"
  latest_spec = latest_version_spec(dep.name)
  puts "Latest version of #{dep.name}: #{latest_spec.version}"
  puts "So is the #{dep.name} requirement outdated? #{dep.requirement.satisfied_by?(latest_spec.version)}"
  puts "\n"
end

puts "Benchmark with Gem::SpecFetcher\n"

Benchmark.bmbm(10) do |x|
  x.report {
    dependencies.each do |dep|
      latest_spec = latest_version_spec(dep.name)
    end    
  }
end

puts "\n"

puts "Now trying with rubygems API\n"

dependencies.each do |dep|
  puts "Checking dependencies status for #{dep.name}"
  puts "Current required version of #{dep.name}: #{dep.requirement.to_s}"
  latest_spec = api_latest_version_spec(dep.name)
  puts "Latest version of #{dep.name}: #{latest_spec.version}"
  puts "So is the #{dep.name} requirement outdated? #{dep.requirement.satisfied_by?(latest_spec.version)}"
  puts "\n"
end

puts "Benchmark with rubygems API \n"

Benchmark.bmbm(10) do |x|
  x.report {
    dependencies.each do |dep|
      latest_spec = api_latest_version_spec(dep.name)
    end    
  }
end
