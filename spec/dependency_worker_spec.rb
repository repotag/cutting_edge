class MockResponse
  def initialize(status, body)
    @status = status
    @body = body
  end
  
  attr_reader :status
  
  def to_s
    @body
  end
end

describe DependencyWorker do
  let(:worker) { DependencyWorker.new }
  let(:identifier) { 'github/gollum/gollum' }
  let(:test_email) { 'cutting_edge@localhost' }
  let(:lang) { 'ruby' }
  let(:locations) {
    {
      'gollum.gemspec' => 'http://github.bla/gollum/gollum/gollum.gemspec',
      'Gemfile' => 'http://github.bla/gollum/gollum/Gemfile'
    }
  }
  let(:dependency_types) { [:runtime] }
  let(:old_dependencies) {
    mock_dependencies('gollum')
  }
  let(:new_dependencies) {
    mock_dependencies('gollum-updated')
  }

  context 'http fetching files' do
    let(:response_ok) { MockResponse.new(200, 'body') }
    let(:response_not_found) { MockResponse.new(404, 'Not found') }
    let(:url) { locations.first.last }
    before {
      worker.instance_variable_set(:@provider, ::CuttingEdge::GitlabRepository)
    }
    
    it 'uses default headers' do
      worker.instance_variable_set(:@provider, ::CuttingEdge::GithubRepository)
      expect(HTTP).to receive(:headers).with({:accept => 'application/vnd.github.v3.raw'}).exactly(:once).and_call_original
      expect_any_instance_of(HTTP::Client).to receive(:get).with(url).and_return(response_ok)
      expect(worker.send(:http_get, url)).to eq 'body'
    end

    it 'returns body when http get is successful' do
      expect_any_instance_of(HTTP::Client).to receive(:get).with(url).and_return(response_ok)
      expect(worker.send(:http_get, url)).to eq 'body'
    end
    
    it 'uses an auth header when it is set for project' do
      token = 'token'
      header = "Bearer #{token}"
      worker.instance_variable_set(:@auth_token, token)
      expect(::CuttingEdge::GitlabRepository).to receive(:headers).with(token).exactly(:once).and_call_original
      expect(HTTP).to receive(:headers).with({:authorization => 'Bearer token'}).exactly(:once).and_call_original
      expect_any_instance_of(HTTP::Client).to receive(:get).with(url).and_return(response_ok)
      expect(worker.send(:http_get, url)).to eq 'body'
    end
    
    it 'returns body when http get is unsuccessful' do
      expect_any_instance_of(HTTP::Client).to receive(:get).with(url).and_return(response_not_found)
      expect(worker.send(:http_get, url)).to be_nil
    end
        
    it 'handles a timeout' do
      expect_any_instance_of(HTTP::Client).to receive(:get).with(url).and_raise(HTTP::TimeoutError)
      expect(worker).to receive(:log_info)
      expect(worker.send(:http_get, url)).to be_nil
    end
  end
  
  it 'generates results for fetched requirements' do
    worker.instance_variable_set(:@lang, RubyLang)
    fetched = [RubyLang.unknown_dependency('unknown_requirement'), Gem::Version.new('1.0')]
    result_no_requirement = {:no_requirement=>[{:latest=>"1.0", :name=>"unknown_requirement", :required=>"unknown", :type=>:runtime, :url=>nil}], :ok=>[], :outdated_major=>[], :outdated_minor=>[], :outdated_patch=>[], :unknown=>[]}
    expect(worker.send(:get_results, [fetched], dependency_types)).to eq result_no_requirement
    
    fetched = [Gem::Dependency.new('unknown_version', '1.0', :runtime), nil]
    result_no_version = {:no_requirement=>[], :ok=>[], :outdated_major=>[], :outdated_minor=>[], :outdated_patch=>[], :unknown=>[{:latest=>"", :name=>"unknown_version", :required=>"= 1.0", :type=>:runtime, :url=>"https://rubygems.org/gems/unknown_version"}]}
    expect(worker.send(:get_results, [fetched], dependency_types)).to eq result_no_version
  end 
  
  context 'performing' do
  
    before(:each) {
      expect(worker).to receive(:get_from_store).with(identifier).and_return(old_dependencies)
      expect(worker).to receive(:http_get).and_return('fake').exactly(locations.length).times
    }
    
    context 'when the dependencies have changed' do
      let(:dependency_diff) {  {'foobar' => :bad_change, 'gollum-lib' => :bad_change, 'kramdown-parser-gfm' => :good_change} }
    
      before(:each) {
        locations.each_key do |loc|
          expect(RubyLang).to receive(:parse_file).with(loc, 'fake').and_return(mock_fetched_requirements('gollum-updated', loc))
        end
        expect(worker).to receive(:badge_worker).with(identifier).and_return(true)
        expect(worker).to receive(:mail_worker).with(identifier, test_email).and_return(true)
      }
    
      it 'updates the store with newest dependencies' do
        expect(worker).to receive(:add_to_store).with(identifier, new_dependencies).and_return(true)
        expect(worker).to receive(:add_to_store).with("diff-#{identifier}", dependency_diff).and_return(true)
        expect(worker.instance_variable_get(:@nothing_changed)).to be_nil
        worker.perform(identifier, lang, locations, dependency_types, test_email)
        expect(worker.instance_variable_get(:@nothing_changed)).to be false
      end
    
    end

    context 'when the dependencies have not changed' do
    
      before(:each) {
        locations.each_key do |loc|
          expect(RubyLang).to receive(:parse_file).with(loc, 'fake').and_return(mock_fetched_requirements('gollum', loc))
        end
        expect(worker).not_to receive(:badge_worker)
        expect(worker).not_to receive(:mail_worker)
      }
      
      it 'does not update the store' do
        expect(worker).not_to receive(:add_to_store)
        expect(worker.instance_variable_get(:@nothing_changed)).to be_nil
        worker.perform(identifier, lang, locations, dependency_types, test_email)
        expect(worker.instance_variable_get(:@nothing_changed)).to be true
      end
    
    end
  
  end
end
