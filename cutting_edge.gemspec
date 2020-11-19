Gem::Specification.new do |s|
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.rubygems_version = '1.3.5'
  s.required_ruby_version = '>= 2.4'

  s.name              = 'cutting_edge'
  s.version           = '0.1'
  s.date              = '2020-11-02'
  s.license           = 'GPL-3.0-only'

  s.summary     = 'Self-hosted dependency monitoring, including shiny badges.'
  s.description = 'Self-hosted dependency monitoring, including shiny badges.'

  s.authors  = ['Dawa Ometto', 'Bart Kamphorst']
  s.email    = 'd.ometto@gmail.com'
  s.homepage = 'http://github.com/repotag/cutting_edge'

  s.require_paths = %w[lib]

  s.executables = ['cutting_edge']

  s.add_dependency 'gemnasium-parser', '~> 0.1.9'
  s.add_dependency 'hashdiff', '~> 1.0'
  s.add_dependency 'http', '~> 4.3'
  s.add_dependency 'sucker_punch', '~> 2.1'
  s.add_dependency 'sinatra', '~> 2.0'
  s.add_dependency 'moneta', '~> 1.2'
  s.add_dependency 'rufus-scheduler', '~> 3.6'
  s.add_dependency 'sinatra-logger', '~> 0.3'
  s.add_dependency 'toml-rb', '~> 2.0'
  s.add_dependency 'mail', '~> 2.7'
  
  # = MANIFEST =
  s.files = %w[
    Gemfile
    Gemfile.lock
    LICENSE
    Procfile
    README.md
    Rakefile
    bin/cutting_edge
    config.rb
    cutting_edge.gemspec
    heroku.config.rb
    lib/cutting_edge.rb
    lib/cutting_edge/app.rb
    lib/cutting_edge/langs.rb
    lib/cutting_edge/langs/python.rb
    lib/cutting_edge/langs/ruby.rb
    lib/cutting_edge/langs/rust.rb
    lib/cutting_edge/public/images/error.svg
    lib/cutting_edge/public/images/languages/python.svg
    lib/cutting_edge/public/images/languages/ruby.svg
    lib/cutting_edge/public/images/languages/rust.svg
    lib/cutting_edge/public/images/ok.svg
    lib/cutting_edge/public/javascript/clipboard.min.js
    lib/cutting_edge/public/javascript/cuttingedge.js
    lib/cutting_edge/public/stylesheets/primer.css
    lib/cutting_edge/repo.rb
    lib/cutting_edge/templates/_footer.html.erb
    lib/cutting_edge/templates/_header.html.erb
    lib/cutting_edge/templates/_overview.html.erb
    lib/cutting_edge/templates/badge.svg.erb
    lib/cutting_edge/templates/index.html.erb
    lib/cutting_edge/templates/info.html.erb
    lib/cutting_edge/templates/mail.html.erb
    lib/cutting_edge/versions.rb
    lib/cutting_edge/workers/badge.rb
    lib/cutting_edge/workers/dependency.rb
    lib/cutting_edge/workers/helpers.rb
    lib/cutting_edge/workers/mail.rb
    projects.yml
    spec/app_spec.rb
    spec/badge_worker_spec.rb
    spec/dependency_worker_spec.rb
    spec/email_worker_spec.rb
    spec/fixtures.rb
    spec/fixtures/projects.yml
    spec/langs/python_spec.rb
    spec/langs/ruby_spec.rb
    spec/langs/rust_spec.rb
    spec/repo_spec.rb
    spec/spec_helper.rb
  ]
  # = MANIFEST =
end
