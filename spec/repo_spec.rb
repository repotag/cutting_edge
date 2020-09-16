describe CuttingEdge::Repository do
  context 'GitHub' do
    it 'defines a class for GitHub.com' do
      expect(CuttingEdge::GithubRepository).to_not be_nil
      github = CuttingEdge::GithubRepository.new('org', 'name')
      expect(github.source).to eq 'github'
      expect(github.url_for_file('file')).to eq 'https://raw.githubusercontent.com/org/name/master/file'
      expect(github.url_for_project).to eq 'https://github.com/org/name'
    end
  end
  
  context 'dynamic definitions' do
  
    it 'defines a class for GitLab.com' do
      expect(CuttingEdge::GitlabRepository).to_not be_nil
      gitlab = CuttingEdge::GitlabRepository.new('org', 'name')
      expect(gitlab.source).to eq 'gitlab'
      expect(gitlab.url_for_file('file')).to eq 'https://gitlab.com/org/name/raw/master/file'
      expect(gitlab.url_for_project).to eq 'https://gitlab.com/org/name'
    end
    
    it 'dynamically defines providers' do
      expect(defined?(CuttingEdge::GiteaRepository)).to be_nil
      define_gitea_server('gitea', 'https://mydependencymonitoring.com')
      expect(defined?(CuttingEdge::GiteaRepository)).to_not be_nil
      gitea = CuttingEdge::GiteaRepository.new('org', 'name')
      expect(gitea.source).to eq 'gitea'
      expect(gitea.url_for_file('file')).to eq 'https://mydependencymonitoring.com/org/name/raw/branch/master/file'
      expect(gitea.url_for_project).to eq 'https://mydependencymonitoring.com/org/name'
    end
  end
end