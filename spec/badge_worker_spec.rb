standard_svg = <<EOF
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="100" height="20" role="img" aria-label="CuttingEdge Dependency Status">
    <title>CuttingEdge Dependency Status</title>
    <linearGradient id="s" x2="0" y2="100%">
        <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
        <stop offset="1" stop-opacity=".1"/>
    </linearGradient>
    <clipPath id="r">
        <rect width="100" height="20" rx="3" fill="#fff"/>
    </clipPath>
    <g clip-path="url(#r)">
        <rect width="35" height="20" fill="#555"/>
        
        <rect x="25" width="25" height="20" fill="#4c1"/>
        
        <rect x="50" width="25" height="20" fill="#fe7d37"/>
        
        <rect x="75" width="25" height="20" fill="#e05d44"/>
        
        <rect width="100" height="20" fill="url(#s)"/>
    </g>
    <g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" text-rendering="geometricPrecision" font-size="110">
        
        <text aria-hidden="true" x="125" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)">CE</text>
        <text x="125" y="140" transform="scale(.1)" fill="#fff">CE</text>
        
        
        <g>
          <title>Ok: 3</title>
          <text aria-hidden="true" x="370" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)">3</text>
          <text x="370" y="140" transform="scale(.1)" fill="#fff">3</text>        
        </g>
        
        <g>
          <title>Outdated Minor: 1</title>
          <text aria-hidden="true" x="620" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)">1</text>
          <text x="620" y="140" transform="scale(.1)" fill="#fff">1</text>        
        </g>
        
        <g>
          <title>Outdated Major: 3</title>
          <text aria-hidden="true" x="870" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)">3</text>
          <text x="870" y="140" transform="scale(.1)" fill="#fff">3</text>        
        </g>
        
    </g>
</svg>
EOF
describe BadgeWorker do
  let(:worker) { BadgeWorker.new }
  let(:identifier) { 'github/gollum/gollum' }

  let(:dependencies) {
    mock_dependencies('gollum')
  }
  
  context 'performing' do
  
    it 'generates an svg for outdated dependencies' do
      expect(worker).to receive(:get_from_store).with(identifier).and_return(dependencies)
      expect(worker).to receive(:add_to_store).with("svg-#{identifier}", standard_svg.chomp).and_return(true)
      worker.perform(identifier)
    end
    
    it 'shows an error badge when there are no dependencies' do
      expect(worker).to receive(:get_from_store).with(identifier).and_return(nil)
      expect(worker).to receive(:add_to_store).with("svg-#{identifier}", CuttingEdge::BADGE_ERROR).and_return(true)
      worker.perform(identifier)
    end
    
    it 'shows an ok badge when up to date' do
      expect(worker).to receive(:get_from_store).with(identifier).and_return(mock_dependencies('ok'))
      expect(worker).to receive(:add_to_store).with("svg-#{identifier}", CuttingEdge::BADGE_OK).and_return(true)
      worker.perform(identifier)
    end
  end
end