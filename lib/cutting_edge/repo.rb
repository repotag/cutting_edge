require File.expand_path('../langs.rb', __FILE__)

module CuttingEdge
  module RepositoryMixin    
    def host
      self.class.class_variable_get(:@@host)
    end
    
    def source
      self.class.class_variable_get(:@@source)
    end
    
    class << self
      def included(base)
        base.extend ClassMethods
      end
    end
    
    module ClassMethods       
      def set_source(source)
        class_variable_set(:@@source, source)
      end
      
      def set_hostname(host)
        class_variable_set(:@@host, host)
      end
    end
  end
  
  module GithubMixin
    class << self
      def included(base)
        base.extend ClassMethods
      end
    end
    
    module ClassMethods
      def headers(auth_token)
        headers = {:accept => 'application/vnd.github.v3.raw'}
        headers[:authorization] = "token #{auth_token}" if auth_token
        headers
      end
    end
  end
  
  module GitlabMixin    
    def url_for_project
      File.join(host, @org, @name)
    end
    
    def url_for_file(file)
      File.join(host, '/api/v4/projects', "#{@org}%2f#{@name}", 'repository/files/', file.gsub('/', '%2f'), "raw?ref=#{@branch}")
    end
    
    class << self
      def included(base)
        base.extend ClassMethods
      end
    end
    
    module ClassMethods
      def headers(auth_token)
        auth_token ? {:authorization => "Bearer #{auth_token}"} : {}
      end
    end
  end
  
  module GiteaMixin
    def url_for_project
      File.join(host, @org, @name)
    end
    
    def url_for_file(file)
      File.join(host, 'api/v1/repos', @org, @name, 'raw', @branch, file)
    end
  end
  
  class Repository
    DEPENDENCY_TYPES = [:runtime] # Which dependency types to accept (default only :runtime, excludes :development).
    DEFAULT_LANG = 'ruby'

    attr_reader :locations, :lang, :contact_email, :auth_token
    attr_accessor :dependency_types
    
    class << self
      def headers(auth_token)
        {}
      end
    end

    def initialize(org:, name:, lang: nil, locations: nil, branch: nil, email: nil, auth_token: nil, hide: nil)
      @org     = org
      @name    = name
      @auth_token = auth_token
      @branch  = branch  || 'main'
      @hidden  = hide
      @lang    = lang || DEFAULT_LANG
      @contact_email = email
      @locations = {}
      (locations || get_lang(@lang).locations(name)).each do |loc|
        @locations[loc] = url_for_file(loc)
      end
      @dependency_types = DEPENDENCY_TYPES
    end
    
    def hidden_token
      @hidden
    end
    
    def hidden?
      !!@hidden
    end

    def source
      ''
    end

    def identifier
      File.join(source, @org, @name)
    end
    
    def url_for_project
      ''
    end

    def url_for_file(file)
      file
    end

    private

    def get_lang(lang)
      Object.const_get("::#{lang.capitalize}Lang")
    end
  end

  class GithubRepository < Repository
    include CuttingEdge::GithubMixin
    
    HOST = 'https://api.github.com'
    
    def source
      'github'
    end
    
    def url_for_project
      File.join('https://github.com', @org, @name)
    end

    def url_for_file(file)
      File.join(HOST, 'repos', @org, @name, 'contents', "#{file}?ref=#{@branch}")
    end
  end  
end

def define_server(id, host, mixin)
  CuttingEdge.const_set("#{id.capitalize}Repository", Class.new(CuttingEdge::Repository) {
      include CuttingEdge::RepositoryMixin
      include mixin
      set_hostname host
      set_source id
    })
end

def define_gitlab_server(id, host)
  define_server(id, host, CuttingEdge::GitlabMixin)
end

def define_gitea_server(id, host)
  define_server(id, host, CuttingEdge::GiteaMixin)
end

define_gitlab_server('gitlab', 'https://gitlab.com/')