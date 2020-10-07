describe CuttingEdge::Repository do
  
  it 'is capable of being hidden' do
    expect(CuttingEdge::Repository.new(org: 'org', name: 'name').hidden?).to be false
    hide_token = 'mytoken'
    repo_with_hide = CuttingEdge::Repository.new(org: 'org', name: 'name', hide: hide_token)
    expect(repo_with_hide.hidden?).to be true
    expect(repo_with_hide.hidden_token).to eq hide_token
  end
  
  it 'has a headers method' do
    expect(CuttingEdge::Repository.headers(nil)).to eq ({})
  end
  
  context 'GitHub' do
    it 'has a headers method' do
      expect(CuttingEdge::GithubRepository.headers(nil)).to eq ({:accept => 'application/vnd.github.v3.raw'})
      expect(CuttingEdge::GithubRepository.headers('token')).to eq ({:accept => 'application/vnd.github.v3.raw', :authorization => 'token token'})
    end
    
    it 'defines a class for GitHub.com' do
      expect(CuttingEdge::GithubRepository).to_not be_nil
      github = CuttingEdge::GithubRepository.new(org: 'org', name: 'name')
      expect(github.source).to eq 'github'
      expect(github.url_for_file('file')).to eq 'https://api.github.com/repos/org/name/contents/file?ref=master'
      expect(github.url_for_project).to eq 'https://github.com/org/name'
    end
  end
  
  context 'dynamic definitions' do
  
    it 'defines a class for GitLab.com' do
      expect(CuttingEdge::GitlabRepository).to_not be_nil
      expect(CuttingEdge::GitlabRepository.headers(nil)).to eq ({})
      expect(CuttingEdge::GitlabRepository.headers('token')).to eq ({:authorization => 'Bearer token'})
      gitlab = CuttingEdge::GitlabRepository.new(org: 'org', name: 'name')
      expect(gitlab.source).to eq 'gitlab'
      expect(gitlab.url_for_file('file')).to eq 'https://gitlab.com/api/v4/projects/org%2fname/repository/files/file/raw?ref=master'
      expect(gitlab.url_for_project).to eq 'https://gitlab.com/org/name'
    end
    
    it 'dynamically defines providers' do
      expect(defined?(CuttingEdge::GiteaRepository)).to be_nil
      define_gitea_server('gitea', 'https://mydependencymonitoring.com')
      expect(defined?(CuttingEdge::GiteaRepository)).to_not be_nil
      gitea = CuttingEdge::GiteaRepository.new(org: 'org', name: 'name')
      expect(gitea.source).to eq 'gitea'
      expect(gitea.url_for_file('file')).to eq 'https://mydependencymonitoring.com/api/v1/repos/org/name/raw/master/file'
      expect(gitea.url_for_project).to eq 'https://mydependencymonitoring.com/org/name'
    end
  end
end