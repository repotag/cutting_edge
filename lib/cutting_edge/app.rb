require 'rubygems'
require 'sucker_punch'
require 'sinatra'
require 'sinatra/logger'
require 'json'
require 'moneta'

require File.expand_path('../../cutting_edge.rb', __FILE__)
require File.expand_path('../repo.rb', __FILE__)
require File.expand_path('../workers/dependency.rb', __FILE__)
require File.expand_path('../workers/badge.rb', __FILE__)

module CuttingEdgeHelpers
  
  extend WorkerHelpers
  
  def worker_all_badges(repositories)
    repositories.each do |repo|
      worker_generate_badge(repo)
    end
  end

  def worker_generate_badge(repo)
    badge_worker(repo.identifier)
  end

  def worker_fetch_all(repositories)
    repositories.each do |repo|
      worker_fetch(repo)
    end
  end

  def worker_fetch(repo)
    DependencyWorker.perform_async(repo.identifier, repo.lang, repo.locations, repo.dependency_types)
  end
end


module CuttingEdge
   LAST_VERSION_TIMEOUT = 5
   BADGE_WORK_QUEUE = 
  
  class App < Sinatra::Base
    include CuttingEdgeHelpers

    logger filename: "#{settings.environment}.log", level: :trace

    before do
      @store = settings.store
    end

    get %r{/(.+)/(.+)/(.+)/info} do |source, org, name|
      repo_defined?(source, org, name)
      content_type :json
      @store[@repo.identifier].merge({:language => @repo.lang}).to_json # Todo: check whether value exists yet? If not, call worker / wait / timeout?
    end

    get %r{/(.+)/(.+)/(.+)/svg} do |source, org, name|
      repo_defined?(source, org, name)
      content_type 'image/svg+xml'
      @store["svg-#{@repo.identifier}"]
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
end
