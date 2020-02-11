require File.expand_path('../lib/workers/dependency.rb', __FILE__)
require File.expand_path('../lib/gems.rb', __FILE__)
require 'redis'
require 'redis-objects'
require 'json'

Redis::Objects.redis = Redis.new
github_repos = Redis::HashKey.new(:github)
github_repos.clear # Deletes the key from redis

puts github_repos.all.inspect # Nothing here

gollum = GithubGem.new('gollum', 'gollum')
lib    = GithubGem.new('gollum', 'gollum-lib', 'gemspec.rb')
rjgit  = GithubGem.new('repotag', 'rjgit', 'gemspec.rb')

gems = [gollum, lib, rjgit]

gems.each do |gem|
  DependencyWorker.perform_async(gem.identifier, gem.gemspec_location, gem.gemfile_location)
end

sleep 20

puts github_repos.keys.inspect
puts JSON.parse(github_repos['gollum/gollum']).inspect # Yay, content!