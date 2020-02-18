require File.expand_path('../lib/workers/dependency.rb', __FILE__)
require File.expand_path('../lib/repo.rb', __FILE__)
require 'moneta'
require 'pp'
require 'sinatra/logger'

# Mock Sinatra app which defines a store for us to use.
module CuttingEdge
  class App
    def self.store
      @store ||= Moneta.new(:Memory)
    end

    def self.enable_logging
      true
    end
  end
end

def print_gems(gems)
  gems.each do |gem|
    puts "#{gem.identifier}:"
    pp ::CuttingEdge::App.store[gem.identifier]
  end
end

::SemanticLogger.add_appender(file_name: 'development.log')

# Define some gems to fetch the dependencies of
gollum = GithubRepository.new('gollum', 'gollum')
lib    = GithubRepository.new('gollum', 'gollum-lib', 'ruby', ['gemspec.rb', 'Gemfile'])
rjgit  = GithubRepository.new('repotag', 'rjgit')
rails  = GithubRepository.new('rails', 'rails')
flask_dance  = GithubRepository.new('singingwolfboy', 'flask-dance', 'python')
gems = [gollum, lib, rjgit, rails, flask_dance]

# For illustration, print the output of the Moneta store for each gem -- they are all empty!
print_gems(gems)

# Now actually fetch the data via some workers
gems.each do |gem|
  DependencyWorker.perform_async(gem.identifier, gem.lang, gem.locations, gem.dependency_types)
end

sleep 10 # Wait a bit for the workers to finish

# When we now print the contents of the moneta store for each gem, we will actually have data!
print_gems(gems)