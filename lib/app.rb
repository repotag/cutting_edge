require 'sinatra'
require 'sidekiq'
require File.expand_path('../gems.rb', __FILE__)
require File.expand_path('../workers/dependency.rb', __FILE__)
require 'yaml'
require 'redis-objects'

module RubyDepsHelpers
  def worker_fetch_all(repositories)
    repositories.each do |gem|
      worker_fetch(gem)
    end
  end

  def worker_fetch(gem)
    DependencyWorker.perform_async(gem.identifier, gem.gemspec_location, gem.gemfile_location)
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
gitlab:
  cthowl01:
    team-chess-ruby:
      api_token: secret
YAML

options = {
  :port => 4567,
  :bind => '0.0.0.0',
}

class RubyDeps < Sinatra::Base

  include RubyDepsHelpers

  get %r{/(.+)/(.+)/info} do |org, name|
    repo_defined?(org, name)
    Sidekiq.redis do |connection|
      Redis::Objects.redis = connection
    end
    result = Redis::Value.new(@repo.identifier)
    content_type :json
    result.value # Todo: check whether value exists yet? If not, call worker / wait / timeout?
  end

  get %r{/(.+)/(.+)/svg} do |org, name|
    repo_defined?(org, name)
    return 'YAY'
  end

  post %r{/(.+)/(.+)/refresh} do |org, name|
    repo_defined?(org, name)
    if params[:token] == @repo.token
      worker_fetch(@repo)
      status 200
    else
      status 401
    end
  end

  private

  def repo_defined?(org, name)
    halt 404, '404 Not Found' unless @repo = settings.repositories["#{org}/#{name}"]
  end

end

repositories = {}
YAML.load(config).each do |source, orgs|
  orgs.each do |org, value|
    value.each do |repo, settings|
      cfg = settings.is_a?(Hash) ? settings : {}
      gem_class = Object.const_get("#{source.capitalize}Gem")
      gem = gem_class.new(org, repo, cfg.fetch('gemspec', nil), cfg.fetch('gemfile', nil), cfg.fetch('branch', nil), cfg.fetch('api_token', nil))
      repositories["#{org}/#{repo}"] = gem
    end
  end
end

puts "Running Sidekiq..."
include RubyDepsHelpers
worker_fetch_all(repositories.values)

puts "Starting Sinatra..."
RubyDeps.set(:repositories, repositories)
RubyDeps.run!(options)
