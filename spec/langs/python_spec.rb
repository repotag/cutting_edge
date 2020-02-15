require 'langs.rb'

REQUIREMENT_TXT = <<EOF
requests>=2.0
oauthlib
requests-oauthlib>=1.0.0 [PDF]
-e svn+http://myrepo/svn/MyApp#egg=MyApp
Flask>=0.7
urlobject==1.0
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
  context 'requirements.txt' do
    it 'default dependency file is requirements.txt' do
      expect(PythonLang.locations).to eq ['requirements.txt']
    end

    it 'parses requirements.txt' do
      result = PythonLang.parse_file('requirements.txt', REQUIREMENT_TXT)
      expect(result).to be_a Array
      expect(result.length).to eq 6
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

      expect(foo.first.requirement.to_s).to eq '< 0.5.0, >= 0.6'
      expect(bar.first.requirement.to_s).to eq '~> 0.2'
      expect(baz.first.requirement.to_s).to eq '~> 0.3.0'
    end
  end
end