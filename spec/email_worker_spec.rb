require 'mail'
Mail.defaults do
  delivery_method :test
end

describe MailWorker do
  let(:worker) { MailWorker.new }
  let(:identifier) { 'github/repotag/cutting_edge' }
  let(:test_email) { 'cutting_edge@localhost' }
  let(:dependencies) {
    mock_dependencies('gollum')
  }
  
  before(:each) {
    expect(worker).to receive(:get_from_store).with(identifier).and_return(dependencies)
  }
  
  it 'returns nil when to address is nil ' do  
    expect(worker.perform(identifier, nil)).to eq nil
  end
  
  it 'sends an update mail' do
    expect(Mail::TestMailer.deliveries).to be_empty
    worker.perform(identifier, test_email)
    expect(Mail::TestMailer.deliveries).to_not be_empty
    
    mail = Mail::TestMailer.deliveries.first
    expect(mail.from.first).to eq 'cutting_edge@localhost'
    expect(mail.to.first).to eq test_email
    expect(mail.subject).to eq  "Dependency Status Changed For #{identifier}"
    
    body = mail.body
    expect(body.parts.length).to eq 2
    
    html_body = body.parts.last.to_s
    expect(html_body).to start_with('Content-Type: text/html')
    expect(html_body).to include('This is <a href="http://localhost">CuttingEdge</a> informing you')
    expect(html_body).to include('In gollum.gemspec: {:outdated_major=>[{:name=>"mustache",')
    expect(html_body).to include('In Gemfile: {:outdated_major=>[{:name=>"rake", ')
  end
end