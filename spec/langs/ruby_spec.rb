GEMSPEC = <<EOF
s.rubygems_version = '1.3.5'
s.required_ruby_version = '>= 2.4'

s.name              = 'cutting_edge'
s.version           = '0.0.1'
s.date              = '2020-02-19'
s.license           = 'GPL-3.0-only'

s.summary     = 'Self-hosted dependency monitoring, including shiny badges.'
s.description = 'Self-hosted dependency monitoring, including shiny badges.'

s.authors  = ['Dawa Ometto', 'Bart Kamphorst']
s.email    = 'd.ometto@gmail.com'
s.homepage = 'http://github.com/repotag/cutting_edge'

s.require_paths = %w[lib]

s.executables = ['cutting_edge']

s.add_dependency 'gemnasium-parser', '~> 0.1.9'
s.add_dependency 'http', '~> 4.3'
s.add_dependency 'sucker_punch', '~> 2.1'
s.add_dependency 'sinatra', '~> 2.0'
s.add_dependency 'moneta', '~> 1.2'
s.add_dependency 'victor', '~> 0.2.8'
s.add_dependency 'rufus-scheduler', '~> 3.6'
s.add_dependency 'sinatra-logger', '~> 0.3'
s.add_dependency 'toml-rb', '~> 2.0'
EOF

GEMFILE = <<EOF
source 'https://rubygems.org'

gem 'redis', require: false
gem 'mail'

gem 'hashdiff'

gem 'rspec', '~> 3.9', :group => :development
gem 'simplecov', :group => :development

gem 'coveralls', '~>0.8.23', require: false

gemspec
EOF

describe RubyLang do
  let(:gemfile_latest_versions) {
    {
      'redis': Gem::Version.new('4.2.2'),
      'mail': Gem::Version.new('2.7.1'),
      'hashdiff': Gem::Version.new('1.0.1'),
      'rspec': Gem::Version.new('3.9.0'),
      'simplecov': Gem::Version.new('0.19.0'),
      'coveralls': Gem::Version.new('0.8.23'),
    }
  }
  let(:gemspec_latest_versions) {
    {
      'gemnasium-parser': Gem::Version.new('0.1.9'),
      'http': Gem::Version.new('4.4.1'),
      'sucker_punch': Gem::Version.new('2.1.2'),
      'sinatra': Gem::Version.new('2.1.0'),
      'moneta': Gem::Version.new('1.4.0'),
      'victor': Gem::Version.new('0.3.2'),
      'rufus-scheduler': Gem::Version.new('3.6.0'),
      'sinatra-logger': Gem::Version.new('0.3.2'),
      'toml-rb': Gem::Version.new('2.0.1'),
    }
  }
  
  it 'expects the default dependency files to be gemspec and Gemfile' do
    expect(RubyLang.locations('test')).to eq ['test.gemspec', 'Gemfile']
  end

  it 'parses gemspec' do
    expect(RubyLang).to receive(:latest_version).and_return(*gemspec_latest_versions.values)
    results = RubyLang.parse_file('test.gemspec', GEMSPEC)
    expect(results.length).to eq 9
    expect(results.last.first).to be_a Bundler::Dependency
    expect(results.last.first.name).to eq 'toml-rb'
    expect(results.last.last).to be_a Gem::Version
    expect(results.last.last.to_s).to eq '2.0.1'
  end
  
  it 'parses gemfile' do
    expect(RubyLang).to receive(:latest_version).and_return(*gemfile_latest_versions.values)
    results = RubyLang.parse_file('Gemfile', GEMFILE)
    expect(results.length).to eq 6
    expect(results.last.first).to be_a Bundler::Dependency
    expect(results.last.first.name).to eq 'coveralls'
    expect(results.last.last.to_s).to eq '0.8.23'
  end
end