require 'mail'
Mail.defaults do
  delivery_method :test
end

describe MailWorker do
  let(:worker) { MailWorker.new }
  let(:identifier) { 'github/repotag/cutting_edge' }
  let(:test_email) { 'cutting_edge@localhost' }
  let(:dependencies) {
    {
      'gollum.gemspec' =>
        {:outdated_major=>
          [{:name=>'mustache',
            :required=>'>= 0.99.5, < 1.0.0',
            :latest=>'1.1.1',
            :type=>:runtime},
           {:name=>'octicons',
            :required=>'~> 8.5',
            :latest=>'9.6.0',
            :type=>:runtime}],
         :outdated_minor=>
          [{:name=>'kramdown-parser-gfm',
            :required=>'~> 1.0.0',
            :latest=>'1.1.0',
            :type=>:runtime}],
         :outdated_patch=>[],
         :ok=>
          [{:name=>'gollum-lib',
            :required=>'~> 5.0',
            :latest=>'5.0.3',
            :type=>:runtime}],
          :no_requirement=>[],
          :unknown=>[]},
       'Gemfile' =>
          {
           :outdated_major=>[
              {
                :name=>'rake',
                :required=>'~> 12.3, >= 12.3.3',
                :latest=>'13.0.1',
                :type=>:runtime
              }],
           :outdated_minor=>[],
           :outdated_patch=>[],
           :ok=>
            [{:name=>'warbler', :required=>'>= 0', :latest=>'2.0.5', :type=>:runtime}],
           :no_requirement=>[],
           :unknown=>[]
         },
         :outdated_major=>5,
         :outdated_total=>17,
         :outdated=>:outdated_major,
         :outdated_minor=>1,
         :outdated_patch=>0,
         :ok=>11,
         :no_requirement=>0,
         :unknown=>0
    }
  }
    
  it 'sends an update mail' do
    expect(Mail::TestMailer.deliveries).to be_empty
    expect(worker).to receive(:get_from_store).with(identifier).and_return(dependencies)
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