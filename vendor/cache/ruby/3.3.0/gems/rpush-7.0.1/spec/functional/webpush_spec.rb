require 'functional_spec_helper'

describe 'Webpush' do
  let(:code) { 201 }
  let(:response) { instance_double('Net::HTTPResponse', code: code, body: '') }
  let(:http) { instance_double('Net::HTTP::Persistent', request: response, shutdown: nil) }
  let(:app) { Rpush::Webpush::App.create!(name: 'MyApp', vapid_keypair: VAPID_KEYPAIR) }

  let(:device_reg) {
    { endpoint: 'https://webpush-provider.example.org/push/some-id',
      expirationTime: nil,
      keys: {'auth' => 'DgN9EBia1o057BdhCOGURA', 'p256dh' => 'BAtxJ--7vHq9IVm8utUB3peJ4lpxRqk1rukCIkVJOomS83QkCnrQ4EyYQsSaCRgy_c8XPytgXxuyAvRJdnTPK4A'} }
  }
  let(:notification) { Rpush::Webpush::Notification.create!(app: app, registration_ids: [device_reg], data: { message: 'test' }) }

  before do
    allow(Net::HTTP::Persistent).to receive_messages(new: http)
  end

  it 'deliveres a notification successfully' do
    expect { Rpush.push }.to change { notification.reload.delivered }.to(true)
  end

  context 'when delivery failed' do
    let(:code) { 404 }
    it 'marks a notification as failed' do
      expect { Rpush.push }.to change { notification.reload.failed }.to(true)
    end
  end
end

