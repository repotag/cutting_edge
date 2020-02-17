require File.expand_path('../../lib/app.rb', __FILE__)
require 'yaml'
require 'rufus-scheduler'

config = <<YAML
github:
  gollum:
    gollum:
      api_token: secret
    gollum-lib:
      api_token: secret
      locations: [gemspec.rb]
      dependency_types: [runtime, development]
  singingwolfboy:
    flask-dance:
      language: python
gitlab:
  cthowl01:
    team-chess-ruby:
      api_token: secret
YAML

options = {
  :port => 4567,
  :bind => '0.0.0.0',
}

store = Moneta.new(:Memory)

repositories = {}
YAML.load(config).each do |source, orgs|
  orgs.each do |org, value|
    value.each do |name, settings|
      cfg = settings.is_a?(Hash) ? settings : {}
      repo = Object.const_get("#{source.capitalize}Repository").new(org, name, cfg.fetch('language', nil), cfg.fetch('locations', nil), cfg.fetch('branch', nil), cfg.fetch('api_token', nil))
      repo.dependency_types = cfg['dependency_types'].map {|dep| dep.to_sym} if cfg['dependency_types'].is_a?(Array)
      repositories["#{source}/#{org}/#{name}"] = repo
    end
  end
end

# Need to initialize the log like this once, because otherwise it only becomes available after the Sinatra app has received a request...
::SemanticLogger.add_appender(file_name: "#{RubyDeps.environment}.log")

RubyDeps.set(:repositories, repositories)
RubyDeps.set(:store, store)
RubyDeps.set(:enable_logging, true)

puts "Scheduling Jobs..."
scheduler = Rufus::Scheduler.new
scheduler.every('1h') do
  worker_fetch_all(repositories.values)
end
scheduler.every('1h5m') do
  worker_all_badges(repositories.values)
end

puts "Running Workers a first time..."
include RubyDepsHelpers
worker_fetch_all(repositories.values)

sleep 5
worker_all_badges(repositories.values)

puts "Starting Sinatra..."
RubyDeps.run!(options)