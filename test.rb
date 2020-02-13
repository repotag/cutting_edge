require File.expand_path('../lib/workers/dependency.rb', __FILE__)
require File.expand_path('../lib/gems.rb', __FILE__)
require 'moneta'
require 'pp'

# Mock Sinatra app which defines a store for us to use.
class RubyDeps
  def self.store
    @store ||= Moneta.new(:Memory)
  end
end

def print_gems(gems)
  gems.each do |gem|
    puts "#{gem.identifier}:"
    pp ::RubyDeps.store[gem.identifier]
  end
end

# Define some gems to fetch the dependencies of
gollum = GithubGem.new('gollum', 'gollum')
lib    = GithubGem.new('gollum', 'gollum-lib', 'gemspec.rb')
rjgit  = GithubGem.new('repotag', 'rjgit', 'gemspec.rb')
rails  = GithubGem.new('rails', 'rails')
gems = [gollum, lib, rjgit, rails]

# For illustration, print the output of the Moneta store for each gem -- they are all empty!
print_gems(gems)

# Now actually fetch the data via some workers
gems.each do |gem|
  DependencyWorker.perform_async(gem.identifier, gem.gemspec_location, gem.gemfile_location, gem.dependency_types)
end

sleep 10 # Wait a bit for the workers to finish

# When we now print the contents of the moneta store for each gem, we will actually have data!
print_gems(gems)