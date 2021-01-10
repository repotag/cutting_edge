REQUIREMENT_TXT = <<EOF
requests   >=  2.0
oauthlib
requests-oauthlib>=1.0.0 [PDF]
-e svn+http://myrepo/svn/MyApp#egg=MyApp
Flask>=0.7
urlobject==1.0
email-validator ~= 1.1.2
six
EOF

# See https://www.python.org/dev/peps/pep-0440/#version-exclusion
# And https://github.com/pypa/pipfile
PIPFILE = <<EOF
[[source]]
url = 'https://pypi.python.org/simple'
verify_ssl = true
name = 'pypi'

[requires]
python_version = '2.7'

[packages]
requests = { extras = ['socks'] }
records = '>0.5.0'
foo = '!= 0.5.*'
bar = '~=0.2'
baz = '=0.3.*'
django = { git = 'https://github.com/django/django.git', ref = '1.11.4', editable = true }
"e682b37" = {file = "https://github.com/divio/django-cms/archive/release/3.4.x.zip"}
"e1839a8" = {path = ".", editable = true}
pywinusb = { version = "*", os_name = "=='nt'", index="pypi"}

[dev-packages]
nose = '*'
unittest2 = {version = ">=1.0,<3.0", markers="python_version < '2.7.9' or (python_version >= '3.0' and python_version < '3.4')"}
EOF

describe PythonLang do
  
  let(:requirements_latest_versions) {
    {
      'requests': Gem::Version.new('2.24.0'),
      'oauthlib': Gem::Version.new('3.1.0'),
      'requests-oauthlib': Gem::Version.new('1.3.0'),
      'Flask': Gem::Version.new('1.1.2'),
      'urlobject': Gem::Version.new('2.4.3'),
      'email-validator': Gem::Version.new('1.1.2'),
      'six': Gem::Version.new('1.15.0'),
    }
  }
  let(:pipfile_latest_versions) {
    {
      'records': Gem::Version.new('0.5.3'),
      'foo': Gem::Version.new('0.1'),
      'bar': Gem::Version.new('0.2.1'),
      'baz': Gem::Version.new('0.2.6'),
      'pywinusb': Gem::Version.new('0.4.2'),
      'nose': Gem::Version.new('1.3.7'),
      'unittest2': Gem::Version.new('1.1.0')
    }
  }
    
  it 'expects the default dependency files to be requirements.txt and Pipfile' do
    expect(PythonLang.locations).to eq ['requirements.txt', 'Pipfile']
  end
  
  it 'returns a website for a dependency' do
    expect(PythonLang.website('foobar')).to eq 'https://pypi.org/project/foobar'
  end
  
  it 'fetches latest version' do
    mock = OpenStruct.new(
      parse: {'info' => {'version' => '1.0.0'}}
    )
    allow_any_instance_of(HTTP::Client).to receive(:get).with('https://pypi.org/pypi/sinatra/json').and_return(mock)
    expect(Gem::Version).to receive(:new).with('1.0.0').and_call_original
    PythonLang.latest_version('sinatra')
    
    allow_any_instance_of(HTTP::Client).to receive(:get).and_raise(HTTP::Error)
    expect(PythonLang.latest_version('fail')).to be_nil
  end

  context 'requirements.txt' do
    it 'parses requirements.txt' do
      expect(PythonLang).to receive(:latest_version).and_return(*requirements_latest_versions.values)
      result = PythonLang.parse_file('requirements.txt', REQUIREMENT_TXT)
      expect(result).to be_a Array
      expect(result.length).to eq 7
      result.each do |dep, version|
        expect(dep).to be_a Gem::Dependency
        expect(dep.type).to eq :runtime
        expect(version.version).to match /\d\.\d.*/
      end
    end
  end

  context 'pipfile' do
    it 'fails softly on invalid Pipfile' do
      expect(PythonLang.parse_file('Pipfile', 'waa')).to eq []
    end

    it 'parses Pipefile' do
      expect(PythonLang).to receive(:latest_version).and_return(*pipfile_latest_versions.values)

      result = PythonLang.parse_file('Pipfile', PIPFILE)
      expect(result).to be_a Array

      dev = result.select {|r| r.first.type == :development}
      run = result.select {|r| r.first.type == :runtime}
      expect(dev.length).to eq 2
      expect(run.length).to eq 9

      expect(run.first.first).to be_a OpenStruct
      expect(run.first.first.requirement).to eq 'unknown'
      expect(run.first.last).to be_nil
      expect(dev.first.first.requirement.to_s).to eq '>= 0'
      expect(dev.first.last.version).to match /\d\.\d.*/

      foo = result.find {|r| r.first.name == 'foo'}
      bar = result.find {|r| r.first.name == 'bar'}
      baz = result.find {|r| r.first.name == 'baz'}

      foo_req = foo.first.requirement.to_s.split(',')
      foo_req.map! {|r| r.strip}
      expect(foo_req).to include('< 0.5.0')
      expect(foo_req).to include('>= 0.6')

      expect(bar.first.requirement.to_s).to eq '~> 0.2'
      expect(baz.first.requirement.to_s).to eq '~> 0.3.0'
    end
  end
end