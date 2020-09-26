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
  
  module GitlabMixin
    def url_for_project
      File.join(host, @org, @name)
    end
    
    def url_for_file(file)
      File.join(host, @org, @name, 'raw', @branch, file)
    end
  end
  
  module GiteaMixin
    def url_for_project
      File.join(host, @org, @name)
    end
    
    def url_for_file(file)
      File.join(host, @org, @name, 'raw', 'branch', @branch, file)
    end
  end
  
  class Repository
    DEPENDENCY_TYPES = [:runtime] # Which dependency types to accept (default only :runtime, excludes :development).
    DEFAULT_LANG = 'ruby'

    attr_reader :locations, :lang, :contact_email
    attr_accessor :dependency_types

    def initialize(org, name, lang = nil, locations = nil, branch = nil, contact_email = nil)
      @org     = org
      @name    = name
      @branch  = branch  || 'master'
      @lang    = lang || DEFAULT_LANG
      @contact_email = contact_email
      @locations = {}
      (locations || get_lang(@lang).locations(name)).each do |loc|
        @locations[loc] = url_for_file(loc)
      end
      @dependency_types = DEPENDENCY_TYPES
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
    HOST = 'https://raw.githubusercontent.com'
    
    def source
      'github'
    end
    
    def url_for_project
      File.join('https://github.com', @org, @name)
    end

    def url_for_file(file)
      File.join(HOST, @org, @name, @branch, file)
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