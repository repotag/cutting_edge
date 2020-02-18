require 'langs.rb'
require 'app.rb'

CARGO = <<EOF
[dependencies]
log = { version = "0.4.*", features = ["std"] }
regex = { version = "1.0.3", optional = true }
termcolor = { version = "^1.0.2", optional = true }
humantime = { version = "~1.3", optional = true }
atty = { version = "0.2.5", optional = true }
my-library = { git = 'https://example.com/git/my-library' }
uuid = "1.0"

[dev-dependencies]
tempdir = "0.3"

[build-dependencies]
cc = "1.0.3"
EOF

def translate_req(str)
  RustLang.send(:translate_requirement, str)
end

describe RustLang do
  it 'expects the default dependency files to be Cargo.toml' do
    expect(RustLang.locations).to eq ['Cargo.toml']
  end

  it 'parses Cargo.toml' do
    results = RustLang.parse_file('Cargo.toml', CARGO)
    expect(results.length).to eq 9

    dev = results.select {|r| r.first.type == :development}
    run = results.select {|r| r.first.type == :runtime}
    build = results.select {|r| r.first.type == :build}

    expect(dev.length).to eq 1
    expect(run.length).to eq 7
    expect(build.length).to eq 1

    expect(run[5].first).to be_a OpenStruct
    expect(run[5].first.requirement).to eq 'unknown'
    expect(run[5].last).to be_nil
    expect(dev.first.first.requirement.to_s).to match />= 0\.3/
    expect(dev.first.first.requirement.to_s).to match /< 0\.4/
    expect(dev.first.last.version).to match /\d\.\d.*/
  end

  context 'translates Rust version requirements to Gem:: compatible requirements' do
    # See https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html
    it 'for the caret operator' do
      # ^1.2.3  :=  >=1.2.3, <2.0.0
      # ^1.2    :=  >=1.2.0, <2.0.0
      # ^1      :=  >=1.0.0, <2.0.0
      # ^0.2.3  :=  >=0.2.3, <0.3.0
      # ^0.2    :=  >=0.2.0, <0.3.0
      # ^0.0.3  :=  >=0.0.3, <0.0.4
      # ^0.0    :=  >=0.0.0, <0.1.0
      # ^0      :=  >=0.0.0, <1.0.0
      expect(translate_req('^1.2.3')).to eq ['>= 1.2.3', '< 2']
      expect(translate_req('^1.2')).to eq ['>= 1.2', '< 2']
      expect(translate_req('^1')).to eq ['>= 1', '< 2']
      expect(translate_req('^0.2.3')).to eq ['>= 0.2.3', '< 0.3']
      expect(translate_req('^0.2')).to eq ['>= 0.2', '< 0.3']
      expect(translate_req('^0.0.3')).to eq ['>= 0.0.3', '< 0.0.4']
      expect(translate_req('^0.0')).to eq ['>= 0.0', '< 0.1']
      expect(translate_req('^0')).to eq ['>= 0', '< 1']
    end

    it 'for the ~ operator' do
      expect(translate_req('~1.2.3')). to eq '~>1.2.3'
    end

    it 'for the * operator' do
      # *     := >=0.0.0         := >= 0
      # 1.*   := >=1.0.0, <2.0.0 := ~> 1.0
      # 1.2.* := >=1.2.0, <1.3.0 := ~> 1.2.0
      expect(translate_req('*')).to eq '>= 0'
      expect(translate_req('1.*')).to eq '~> 1.0'
      expect(translate_req('1.2.*')).to eq '~> 1.2.0'
    end
  end
end