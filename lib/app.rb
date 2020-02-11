require 'sinatra'
require 'sidekiq'
require File.expand_path('../gems.rb', __FILE__)
require File.expand_path('../workers/dependency.rb', __FILE__)
require 'yaml'
require 'redis-objects'

module RubyDepsHelpers
  def fetch_all_repos(repositories)
    repositories.each do |gem|
      fetch_repo(gem)
    end
  end

  def fetch_repo(gem)
    DependencyWorker.perform_async(gem.identifier, gem.gemspec_location, gem.gemfile_location)
  end
end

config = <<YAML
gollum:
  gollum:
    api_token: secret
  gollum-lib:
    api_token: secret
    gemspec: gemspec.rb
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
    result = Redis::Value.new(@identifier)
    content_type :json
    result.value # Todo: check whether value exists yet? If not, call worker / wait / timeout?
  end

  get %r{/(.+)/(.+)/svg} do |org, name|
    repo_defined?(org, name)
    return 'YAY'
  end

  post %r{/(.+)/(.+)/refresh} do |org, name|
    repo_defined?(org, name)
    if params[:token] == settings.repositories[@identifier].token
      fetch_repo(settings.repositories[@identifier])
      status 200
    else
      status 401
    end
  end

  private

  def repo_defined?(org, name)
    @identifier = "#{org}/#{name}"
    halt 404, '404 Not Found' unless settings.repositories.has_key?("#{org}/#{name}")
  end

end

repositories = {}
YAML.load(config).each do |org, value|
  value.each do |repo, settings|
    cfg = settings.is_a?(Hash) ? settings : {}
    gem = GithubGem.new(org, repo, cfg.fetch('gemspec', nil), cfg.fetch('gemfile', nil), cfg.fetch('branch', nil), cfg.fetch('api_token', nil))
    repositories[gem.identifier] = gem
  end
end

puts "Running Sidekiq..."
include RubyDepsHelpers
fetch_all_repos(repositories.values)

puts "Starting Sinatra..."
RubyDeps.set(:repositories, repositories)
RubyDeps.run!(options)
