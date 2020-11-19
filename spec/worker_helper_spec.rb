describe WorkerHelpers do
  include WorkerHelpers
  let(:id) { 'foo' }
  let(:data) {'bar'}
  let(:address) {'test@test.com'}
  
  it 'gets from store' do
    expect(::CuttingEdge::App.store).to receive(:[]).with(id).and_return(true)
    expect(get_from_store(id)).to be true
  end
  
  it 'deletes from store' do
    expect(::CuttingEdge::App.store).to receive(:delete).with(id).and_return(true)
    expect(delete_from_store(id)).to eq true
  end
  
  it 'adds to store' do
    expect(::CuttingEdge::App.store).to receive(:[]=).with(id, data).and_return(data)
    expect(add_to_store(id, data)).to eq data
  end
  
  it 'runs BadgeWorker' do
    expect(BadgeWorker).to receive(:perform_async).with(id).and_return(true)
    expect(badge_worker(id)).to eq true
  end
  
  it 'runs MailWorker' do
    expect(MailWorker).to receive(:perform_async).with(id, address).and_return(true)
    expect(mail_worker(id, address)).to eq true
  end
end