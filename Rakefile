require 'rubygems'
require 'date'
require 'tempfile'
require 'rspec/core/rake_task'

task :default => :rspec

desc "Run specs."
RSpec::Core::RakeTask.new(:rspec) do |spec|
  ruby_opts = "-w"
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rspec_opts = ['--backtrace --color']
end

#############################################################################
#
# Helper functions
#
#############################################################################

def name
  @name ||= Dir['*.gemspec'].first.split('.').first
end

def version
  line = File.read("lib/#{name}.rb")[/^\s*VERSION\s*=\s*.*/]
  line.match(/.*VERSION\s*=\s*['"](.*)['"]/)[1]
end

def latest_changes_file
  'LATEST_CHANGES.md'
end

def history_file
  'HISTORY.md'
end

# assumes x.y.z all digit version
def next_version
  # x.y.z
  v = version.split '.'
  # bump z
  v[-1] = v[-1].to_i + 1
  v.join '.'
end

def bump_version
  old_file = File.read("lib/#{name}.rb")
  old_version_line = old_file[/^\s*VERSION\s*=\s*.*/]
  new_version = next_version
  # replace first match of old vesion with new version
  old_file.sub!(old_version_line, "  VERSION = '#{new_version}'")

  File.write("lib/#{name}.rb", old_file)

  new_version
end

def date
  Date.today.to_s
end

def gemspec_file
  "#{name}.gemspec"
end

def gem_file
  "#{name}-#{version}.gem"
end

def replace_header(head, header_name)
  head.sub!(/(\.#{header_name}\s*= ').*'/) { "#{$1}#{send(header_name)}'"}
end

#############################################################################
#
# Custom tasks (add your own tasks here)
#
#############################################################################

desc "Update version number and gemspec"
task :bump do
  puts "Updated version to #{bump_version}"
  # Execute does not invoke dependencies.
  # Manually invoke gemspec then validate.
  Rake::Task[:gemspec].execute
  Rake::Task[:validate].execute
end

#############################################################################
#
# Packaging tasks
#
#############################################################################

desc 'Create a release build and push to rubygems'
task :release => :build do
  unless `git branch` =~ /^\* main$/
    puts "You must be on the main branch to release!"
    exit!
  end
  Rake::Task[:changelog].execute
  sh "git commit --allow-empty -a -m 'Release #{version}'"
  sh "git pull --rebase origin main"
  sh "git tag v#{version}"
  sh "git push origin main"
  sh "git push origin v#{version}"
  sh "gem push pkg/#{name}-#{version}.gem"
end

desc 'Publish to rubygems. Same as release'
task :publish => :release

desc 'Build gem'
task :build => :gemspec do
  sh "mkdir -p pkg"
  sh "gem build #{gemspec_file}"
  sh "mv #{gem_file} pkg"
end

desc "Build and install"
task :install => :build do
  sh "gem install --local --no-document pkg/#{name}-#{version}.gem"
end

desc 'Update gemspec'
task :gemspec => :validate do
  # read spec file and split out manifest section
  spec = File.read(gemspec_file)
  head, manifest, tail = spec.split("  # = MANIFEST =\n")

  # replace name version and date
  replace_header(head, :name)
  replace_header(head, :version)
  replace_header(head, :date)

  # determine file list from git ls-files
  files = `git ls-files`.
    split("\n").
    sort.
    reject { |file| file =~ /^\./ }.
    reject { |file| file =~ /^(rdoc|pkg|test|Home\.md|\.gitattributes)/ }.
    map { |file| "    #{file}" }.
    join("\n")

  # piece file back together and write
  manifest = "  s.files = %w[\n#{files}\n  ]\n"
  spec = [head, manifest, tail].join("  # = MANIFEST =\n")
  File.open(gemspec_file, 'w') { |io| io.write(spec) }
  puts "Updated #{gemspec_file}"
end

desc 'Validate lib files and version file'
task :validate do
  libfiles = Dir['lib/*'] - ["lib/#{name}.rb", "lib/#{name}"]
  unless libfiles.empty?
    puts "Directory `lib` should only contain a `#{name}.rb` file and `#{name}` dir."
    exit!
  end
  unless Dir['VERSION*'].empty?
    puts "A `VERSION` file at root level violates Gem best practices."
    exit!
  end
end

desc 'Build changelog'
task :changelog do
  [latest_changes_file, history_file].each do |f|
    unless File.exists?(f)
      puts "#{f} does not exist but is required to build a new release."
      exit!
    end
  end

  latest_changes = File.open(latest_changes_file)
  version_pattern = "# #{version}"

  if !`grep "#{version_pattern}" #{history_file}`.empty?
    puts "#{version} is already described in #{history_file}"
    exit!
  end

  begin
    unless latest_changes.readline.chomp! =~ %r{#{version_pattern}}
      puts "#{latest_changes_file} should begin with '#{version_pattern}'"
      exit!
    end
  rescue EOFError
    puts "#{latest_changes_file} is empty!"
    exit!
  end

  body = latest_changes.read
  body.scan(/\s*#\s+\d\.\d.*/) do |match|
    puts "#{latest_changes_file} may not contain multiple markdown headers!"
    exit!
  end

  temp = Tempfile.new
  temp.puts("#{version_pattern} / #{date}\n#{body}\n")
  temp.close
  `cat #{history_file} >> #{temp.path}`
  `cat #{temp.path} > #{history_file}`
end