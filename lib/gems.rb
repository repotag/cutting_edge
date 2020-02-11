class GithubGem
  HOST = 'https://raw.githubusercontent.com'

  attr_reader :token

  def initialize(org, name, gemspec = nil, gemfile = nil, branch = nil, token = nil)
    @org     = org
    @name    = name
    @gemspec = gemspec || "#{name.downcase}.gemspec"
    @gemfile = gemfile || 'Gemfile'
    @branch  = branch  || 'master'
    @token   = token
  end

  def source
    'github'
  end

  def gemfile_location
    File.join(HOST, @org, @name, @branch, @gemfile)
  end

  def gemspec_location
    File.join(HOST, @org, @name, @branch, @gemspec)
  end

  def identifier
    File.join(source, @org, @name)
  end
end

class GitlabGem < GithubGem
  HOST = 'https://gitlab.com/'

  def source
    'gitlab'
  end

  def gemfile_location
    File.join(HOST, @org, @name, 'raw', @branch, @gemfile)
  end

  def gemspec_location
    File.join(HOST, @org, @name, 'raw', @branch, @gemspec)
  end
end