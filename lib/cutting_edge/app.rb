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
    DependencyWorker.perform_async(repo.identifier, repo.lang, repo.locations, repo.dependency_types, repo.contact_email, repo.auth_token)
  end
  
  def load_repositories(path)
    repositories = {}
    begin
      YAML.load(File.read(path)).each do |source, orgs|
        orgs.each do |org, value|
          value.each do |name, settings|
            cfg = settings.is_a?(Hash) ? settings : {}
            repo = Object.const_get("CuttingEdge::#{source.capitalize}Repository").new(org, name, cfg.fetch('language', nil), cfg.fetch('locations', nil), cfg.fetch('branch', nil), cfg.fetch('email', CuttingEdge::MAIL_TO), cfg.fetch('auth_token', nil), cfg.fetch('hide', false))
            repo.dependency_types = cfg['dependency_types'].map {|dep| dep.to_sym} if cfg['dependency_types'].is_a?(Array)
            repositories["#{source}/#{org}/#{name}"] = repo
          end
        end
      end
    rescue SyntaxError, Errno::ENOENT => e
      puts "Error: #{path} does not contain a valid YAML project definition."
      if ENV['RACK_ENV'] == 'test'
        return nil
      else
        exit 1
      end
    end
    repositories
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

    get '/' do
      @repos = CuttingEdge::App.repositories.select {|_, repo| !repo.hidden?}
      erb :index
    end

    get %r{/(.+)/(.+)/(.+)/info/json} do |source, org, name|
      repo_defined?(source, org, name)
      content_type :json
      data = @store[@repo.identifier]
      if data
        data.merge({:language => @repo.lang}).to_json
      else
        status 500
      end
    end

    get %r{/(.+)/(.+)/(.+)/info} do |source, org, name|
      repo_defined?(source, org, name)
      @name = name
      @svg = url("/#{source}/#{org}/#{name}/svg")
      @md = "[![Cutting Edge Dependency Status](#{@svg} 'Cutting Edge Dependency Status')](#{url("/#{source}/#{org}/#{name}/info")})"
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
      if defined?(::CuttingEdge::SECRET_TOKEN) && params[:token] == ::CuttingEdge::SECRET_TOKEN
        worker_fetch(@repo)
        status 200
      else
        status 401
      end
    end

    private
    
    def not_found
      halt 404, '404 Not Found'
    end

    def repo_defined?(source, org, name)
      not_found unless @repo = settings.repositories["#{source}/#{org}/#{name}"]
    end
    
  end
end
