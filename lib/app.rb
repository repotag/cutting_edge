require File.expand_path('../gems.rb', __FILE__)
require File.expand_path('../workers/dependency.rb', __FILE__)

require 'sucker_punch'
require 'sinatra'
require 'sinatra/logger'
require 'yaml'
require 'json'
require 'moneta'
require 'rufus-scheduler'

module RubyDepsHelpers
  def worker_fetch_all(repositories)
    repositories.each do |gem|
      worker_fetch(gem)
    end
  end

  def worker_fetch(gem)
    DependencyWorker.perform_async(gem.identifier, gem.gemspec_location, gem.gemfile_location, gem.dependency_types)
  end
end

config = <<YAML
github:
  gollum:
    gollum:
      api_token: secret
    gollum-lib:
      api_token: secret
      gemspec: gemspec.rb
      dependency_types: [runtime, development]
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

class RubyDeps < Sinatra::Base
  include RubyDepsHelpers

  logger filename: "#{settings.environment}.log", level: :trace

  before do
    @store = settings.store
  end

  get %r{/(.+)/(.+)/(.+)/info} do |source, org, name|
    repo_defined?(source, org, name)
    content_type :json
    @store[@repo.identifier].to_json # Todo: check whether value exists yet? If not, call worker / wait / timeout?
  end

  get %r{/(.+)/(.+)/(.+)/svg} do |source, org, name|
    repo_defined?(source, org, name)
    return 'YAY'
  end

  post %r{/(.+)/(.+)/(.+)/refresh} do |source, org, name|
    repo_defined?(source, org, name)
    if @repo.token && params[:token] == @repo.token
      worker_fetch(@repo)
      status 200
    else
      status 401
    end
  end

  private

  def repo_defined?(source, org, name)
    halt 404, '404 Not Found' unless @repo = settings.repositories["#{source}/#{org}/#{name}"]
  end

end

repositories = {}
YAML.load(config).each do |source, orgs|
  orgs.each do |org, value|
    value.each do |repo, settings|
      cfg = settings.is_a?(Hash) ? settings : {}
      gem_class = Object.const_get("#{source.capitalize}Gem")
      gem = gem_class.new(org, repo, cfg.fetch('gemspec', nil), cfg.fetch('gemfile', nil), cfg.fetch('branch', nil), cfg.fetch('api_token', nil))
      gem.dependency_types = cfg['dependency_types'].map {|dep| dep.to_sym} if cfg['dependency_types'].is_a?(Array)
      repositories["#{source}/#{org}/#{repo}"] = gem
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

puts "Running Workers a first time..."
include RubyDepsHelpers
worker_fetch_all(repositories.values)

puts "Starting Sinatra..."
RubyDeps.run!(options)
