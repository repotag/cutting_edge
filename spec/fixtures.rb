def mock_dependencies(name)
  {
    'ok' =>
    {
      :locations => {
        'ok.gemspec' =>
          {:outdated_major=>[],
           :outdated_patch=>[],
           :ok=>
            [
              {:name=>'gollum-lib',
               :required=>'~> 5.0',
               :latest=>'5.0.3',
               :type=>:runtime},
              {:name => 'foobar',
               :required => '= 1.0',
               :latest => '1.0',
               :type => :runtime
             }
            ],
           :no_requirement=>[],
           :unknown=>[]},
      },
      :ok=>2,
      :outdated=>:up_to_date,
      :outdated_major=>0,
      :outdated_minor=>0,
      :outdated_patch=>0,
      :outdated_total=>0,
      :unknown=>0,
      :no_requirement => 0
    },
    'gollum' =>
    {
      :locations=>
        {'gollum.gemspec'=>
          {:outdated_major=>
            [{:name=>'mustache',
              :required=>'>= 0.99.5, < 1.0.0',
              :latest=>'1.1.1',
              :type=>:runtime,
              :url=>'https://rubygems.org/gems/mustache'},
             {:name=>'octicons',
              :required=>'~> 8.5',
              :latest=>'9.6.0',
              :type=>:runtime,
              :url=>'https://rubygems.org/gems/octicons'}],
           :outdated_minor=>
            [{:name=>'kramdown-parser-gfm',
              :required=>'~> 1.0.0',
              :latest=>'1.1.0',
              :type=>:runtime,
              :url=>'https://rubygems.org/gems/kramdown-parser-gfm'}],
           :outdated_patch=>[],
           :ok=>
            [{:name=>'gollum-lib',
              :required=>'~> 5.0',
              :latest=>'5.0.3',
              :type=>:runtime,
              :url=>'https://rubygems.org/gems/gollum-lib'},
             {:name=>'foobar',
              :required=>'= 1.0',
              :latest=>'1.0',
              :type=>:runtime,
              :url=>'https://rubygems.org/gems/foobar'}],
           :no_requirement=>[],
           :unknown=>[]},
         'Gemfile'=>
          {:outdated_major=>
            [{:name=>'rake',
              :required=>'~> 12.3, >= 12.3.3',
              :latest=>'13.0.1',
              :type=>:runtime,
              :url=>'https://rubygems.org/gems/rake'}],
           :outdated_minor=>[],
           :outdated_patch=>[],
           :ok=>
            [{:name=>'warbler',
              :required=>'>= 0',
              :latest=>'2.0.5',
              :type=>:runtime,
              :url=>'https://rubygems.org/gems/warbler'}],
           :no_requirement=>[],
           :unknown=>[]}},
      :ok=>3,
      :outdated=>:outdated_major,
      :outdated_major=>3,
      :outdated_minor=>1,
      :outdated_patch=>0,
      :outdated_total=>4,
      :unknown=>0,
      :no_requirement => 0
    },
    'gollum-updated' =>
      {
        :locations =>
          {'gollum.gemspec'=>
            {:outdated_major=>
              [{:name=>'mustache',
                :required=>'>= 0.99.5, < 1.0.0',
                :latest=>'2.1.1',
                :type=>:runtime,
                :url=>'https://rubygems.org/gems/mustache'},
               {:name=>'octicons',
                :required=>'~> 8.5',
                :latest=>'10.6.0',
                :type=>:runtime,
                :url=>'https://rubygems.org/gems/octicons'},
               {:name=>'kramdown-parser-gfm',
                :required=>'~> 1.0.0',
                :latest=>'2.1.0',
                :type=>:runtime,
                :url=>'https://rubygems.org/gems/kramdown-parser-gfm'},
               {:name=>'gollum-lib',
                :required=>'~> 5.0',
                :latest=>'6.0.3',
                :type=>:runtime,
                :url=>'https://rubygems.org/gems/gollum-lib'},
               {:name=>'foobar',
                :required=>'= 1.0',
                :latest=>'2.0',
                :type=>:runtime,
                :url=>'https://rubygems.org/gems/foobar'}],
             :outdated_minor=>[],
             :outdated_patch=>[],
             :ok=>[],
             :no_requirement=>[],
             :unknown=>[]},
           'Gemfile'=>
            {:outdated_major=>
              [{:name=>'rake',
                :required=>'~> 12.3, >= 12.3.3',
                :latest=>'14.0.1',
                :type=>:runtime,
                :url=>'https://rubygems.org/gems/rake'}],
             :outdated_minor=>[],
             :outdated_patch=>[],
             :ok=>
              [{:name=>'warbler',
                :required=>'>= 0',
                :latest=>'3.0.5',
                :type=>:runtime,
                :url=>'https://rubygems.org/gems/warbler'}],
             :no_requirement=>[],
             :unknown=>[]}},
         :no_requirement=>0,
         :ok=>1,
         :outdated=>:outdated_major,
         :outdated_major=>6,
         :outdated_minor=>0,
         :outdated_patch=>0,
         :outdated_total=>6,
         :unknown=>0,
         :no_requirement => 0
      }
  }[name]
end

def mock_dependencies_no_stats(name)
  stats = DependencyWorker::STATUS_TYPES + [:outdated_total, :outdated]
  mock_dependencies(name).reject {|k,v| stats.include?(k) }
end

def mock_fetched_requirements(name, location, update_latest = false)
  dependencies = mock_dependencies(name)[:locations][location]
  results = []
  dependencies.each_value do |dependency_type|
    dependency_type.each do |dependency|
      gem_dependency = Gem::Dependency.new(dependency[:name], dependency[:required].split(','), dependency[:type])
      latest_version = Gem::Version.new(dependency[:latest])
      if update_latest
        segments = latest_version.segments
        segments[0] = segments[0] + 1
        latest_version = Gem::Version.new(segments.join('.'))
      end
      results << [gem_dependency, latest_version]
    end
  end
  results
end