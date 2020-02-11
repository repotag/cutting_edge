class GithubGem
  HOST = 'https://raw.githubusercontent.com'

  def initialize(org, name, gemspec = nil, gemfile = nil, branch = 'master')
    @org     = org
    @name    = name
    @gemspec = gemspec || "#{name.downcase}.gemspec"
    @gemfile = gemfile || 'Gemfile'
    @branch  = branch
  end

  def gemfile_location
    File.join(HOST, @org, @name, @branch, @gemfile)
  end

  def gemspec_location
    File.join(HOST, @org, @name, @branch, @gemspec)
  end

  def identifier
    File.join(@org, @name)
  end
end