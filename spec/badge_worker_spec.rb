standard_svg = <<EOF
<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="110" height="20" role="img" aria-label="CuttingEdge">
    <title>CuttingEdge Dependency Status</title>
    <linearGradient id="s" x2="0" y2="100%">
        <stop offset="0" stop-color="#bbb" stop-opacity=".1"/>
        <stop offset="1" stop-opacity=".1"/>
    </linearGradient>
    <clipPath id="r">
        <rect width="110" height="20" rx="3" fill="#fff"/>
    </clipPath>
    <g clip-path="url(#r)">
        <rect width="35" height="20" fill="#555"/>
        
        <rect x="35" width="25" height="20" fill="#4c1"/>
        
        <rect x="60" width="25" height="20" fill="orange"/>
        
        <rect x="85" width="25" height="20" fill="red"/>
        
        <rect width="110" height="20" fill="url(#s)"/>
    </g>
    <g fill="#fff" text-anchor="middle" font-family="Verdana,Geneva,DejaVu Sans,sans-serif" text-rendering="geometricPrecision" font-size="110">
        <text aria-hidden="true" x="175" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)">CE</text>
        <text x="175" y="140" transform="scale(.1)" fill="#fff">CE</text>
        
        
        <g>
          <title>Ok: 3</title>
          <text aria-hidden="true" x="470" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)">3</text>
          <text x="470" y="140" transform="scale(.1)" fill="#fff">3</text>        
        </g>
        
        <g>
          <title>Outdated Minor: 1</title>
          <text aria-hidden="true" x="720" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)">1</text>
          <text x="720" y="140" transform="scale(.1)" fill="#fff">1</text>        
        </g>
        
        <g>
          <title>Outdated Major: 3</title>
          <text aria-hidden="true" x="970" y="150" fill="#010101" fill-opacity=".3" transform="scale(.1)">3</text>
          <text x="970" y="140" transform="scale(.1)" fill="#fff">3</text>        
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
  
    before(:each) {
      expect(worker).to receive(:get_from_store).with(identifier).and_return(dependencies)
    }
    
    it 'generates an svg for dependencies' do
      expect(worker).to receive(:add_to_store).with("svg-#{identifier}", standard_svg.chomp).and_return(true)
      worker.perform(identifier)
    end
  end
end