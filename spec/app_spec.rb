require 'spec_helper'

describe CuttingEdgeHelpers do
  it 'fails to load invalid projects.yml' do
    expect(load_repositories('/tmp/fail.yml')).to be_nil
  end
end

describe CuttingEdge::App do
  before(:all) {
    CuttingEdge::App.set(:repositories, load_repositories(File.expand_path('../fixtures/projects.yml', __FILE__)))
    CuttingEdge::App.set(:store, Moneta.new(:Memory))
  }
  let(:app) { CuttingEdge::App.new }

  context 'landing page' do
    let(:response) { get '/' }
    it 'returns status 200 OK' do
      expect(response.status).to eq 200
    end
  end
  
  context 'unknown project' do
    let(:project) { 'github/doesnt/exist' }
    ['/info', '/info/json', '/svg', '/refresh'].each do |route|
      it "returns status 404 not found for #{route}" do
        response = get("/#{project}#{route}")
        expect(response.status).to eq 404
      end
    end
  end
  
  context 'known project' do
    let(:project) { 'github/gollum/gollum' }
    before {
      add_to_store("svg-#{project}", 'test')
      add_to_store(project, {'test' => true})
    }
    {'/info' => 'text/html;charset=utf-8', '/info/json' => 'application/json', '/svg' => 'image/svg+xml'}.each do |route, type|
      it "returns status 200 OK for #{route} with mime #{type}" do
        response = get("/#{project}#{route}")
        expect(response.status).to eq 200
        expect(response.content_type).to eq type
      end
    end
    
    it 'returns status 500 for a known project json without data' do
      response = get("/github/gollum/gollum-lib/info/json")
      # the store contains nothing for gollum-lib
      expect(response.status).to eq 500
    end
  end
  
  context 'hidden repos' do
    let(:project) { 'gitlab/gitlab-org/gitlab-foss' }
    
    it 'does not list hidden repos on the landing page' do
      response = get('/')
      expect(response.body).to include('team-chess-ruby')
      expect(response.body).not_to include('gitlab-foss')
    end
    
    before {
      ::CuttingEdge::SECRET_TOKEN = 'secret'
    }
    after {
      CuttingEdge.send(:remove_const, :SECRET_TOKEN)
    }
    
    it 'returns a JSON encoded HTML partial if the token is correct' do
      response = post('/', "{\"token\":\"secret\"}")
      expect(response.body).to include('gitlab-foss')
      expect(JSON.parse(response.body)['partial']).to include "<div class=\"Box\">"
      expect(JSON.parse(response.body)['partial']).to include "gitlab/gitlab-org/gitlab-foss"
    end
    
  end
  
  context 'refreshing' do
    let(:project) { 'github/gollum/gollum' }
    before {
      ::CuttingEdge::SECRET_TOKEN = 'secret'
    }
    after {
      CuttingEdge.send(:remove_const, :SECRET_TOKEN)
    }
    it 'fails with wrong token' do
      response = post "/#{project}/refresh", :token => 'fail'
      expect(response.status).to eq 401
    end
    it 'succeeds with right token' do
      expect(DependencyWorker).to receive(:perform_async).exactly(:once)
      response = post "/#{project}/refresh", token: 'secret'
      expect(response.status).to eq 200
    end
  end
end