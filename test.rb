require File.expand_path('../lib/workers/dependency.rb', __FILE__)
require File.expand_path('../lib/gems.rb', __FILE__)
require 'redis'
require 'redis-objects'
require 'json'

Redis::Objects.redis = Redis.new

gollum = GithubGem.new('gollum', 'gollum')
lib    = GithubGem.new('gollum', 'gollum-lib', 'gemspec.rb')
rjgit  = GithubGem.new('repotag', 'rjgit', 'gemspec.rb')
rails  = GithubGem.new('rails', 'rails')

gems = [gollum, lib, rjgit, rails]

gems.each do |gem|
  Redis::Objects.redis.del(gem.identifier) # Clear the Redis store
end

gem_dependencies = gems.map do |gem|
  val = Redis::Value.new(gem.identifier)
  puts val.value # Nothing here yet
  val
end

gems.each do |gem|
  DependencyWorker.perform_async(gem.identifier, gem.gemspec_location, gem.gemfile_location)
end

sleep 20

gem_dependencies.each do |val|
  puts val.value # Yay, content!
end

puts JSON.parse(gem_dependencies.first.value).inspect # Yay, content!
puts JSON.parse(gem_dependencies.last.value).inspect # Yay, content!