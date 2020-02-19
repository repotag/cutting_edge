require File.expand_path('../langs.rb', __FILE__)

module CuttingEdge
  class Repository

    DEPENDENCY_TYPES = [:runtime] # Which dependency types to accept (default only :runtime, excludes :development).
    DEFAULT_LANG = 'ruby'

    attr_reader :token, :locations, :lang
    attr_accessor :dependency_types

    def initialize(org, name, lang = nil, locations = nil, branch = nil, token = nil)
      @org     = org
      @name    = name
      @branch  = branch  || 'master'
      @token   = token
      @lang    = lang || DEFAULT_LANG
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

    def url_for_file(file)
      File.join(HOST, @org, @name, @branch, file)
    end
  end

  class GitlabRepository < Repository
    HOST = 'https://gitlab.com/'

    def source
      'gitlab'
    end

    def url_for_file(file)
      File.join(HOST, @org, @name, 'raw', @branch, file)
    end
  end
end