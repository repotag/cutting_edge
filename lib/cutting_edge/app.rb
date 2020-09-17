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
require File.expand_path('../workers/mail.rb', __FILE__)

module CuttingEdgeHelpers
  
  def worker_fetch_all(repositories)
    repositories.each do |repo|
      worker_fetch(repo)
    end
  end

  def worker_fetch(repo)
    DependencyWorker.perform_async(repo.identifier, repo.lang, repo.locations, repo.dependency_types, repo.contact_email)
  end
end

module CuttingEdge
  
  LAST_VERSION_TIMEOUT = 5
  SERVER_HOST = 'localhost' unless defined?(SERVER_HOST)
  SERVER_URL = "http://#{SERVER_HOST}" unless defined?(SERVER_URL)
  MAIL_TO = false unless defined?(MAIL_TO) # Default address to send email to. If set to false, don't send any e-mails except for repositories that have their 'email' attribute set.
  MAIL_FROM = "cutting_edge@#{SERVER_HOST}" unless defined?(MAIL_FROM)
   
  class App < Sinatra::Base
    include CuttingEdgeHelpers

    set :views, ::File.join(::File.dirname(__FILE__), 'templates')
    Tilt.register Tilt::ERBTemplate, 'html.erb'
    set :public_folder, ::File.join(::File.dirname(__FILE__), 'public')

    logger filename: "#{settings.environment}.log", level: :trace

    before do
      @store = settings.store
    end

    get "/" do
      @repos = CuttingEdge::App.repositories
      erb :index
    end

    get %r{/(.+)/(.+)/(.+)/info/json} do |source, org, name|
      repo_defined?(source, org, name)
      content_type :json
      @store[@repo.identifier].merge({:language => @repo.lang}).to_json # Todo: check whether value exists yet? If not, call worker / wait / timeout?
    end

    get %r{/(.+)/(.+)/(.+)/info} do |source, org, name|
      repo_defined?(source, org, name)
      @name = name
      @svg = url("/#{source}/#{org}/#{name}/svg")
      @md = "[![Cutting Edge Dependency Status](#{@svg})](#{url("/#{source}/#{org}/#{name}/info")})"
      @colors = {ok: 'green', outdated_patch: 'yellow', outdated_minor: 'orange', outdated_major: 'red', unknown: 'gray'}
      @specs = @store[@repo.identifier]
      @project_url = @repo.url_for_project
      @language = @repo.lang
      erb :info
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
