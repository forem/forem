require 'unit_spec_helper'

shared_examples 'Rpush::Client::Wns::RawNotification' do
  let(:notification) do
    notif = described_class.new
    notif.app  = Rpush::Wns::App.create!(name: "MyApp", client_id: "someclient", client_secret: "somesecret")
    notif.uri  = 'https://db5.notify.windows.com/?token=TOKEN'
    notif.data = { foo: 'foo', bar: 'bar' }
    notif
  end

  it 'allows exact payload of 5 KB' do
    allow(notification).to receive(:payload_data_size) { 5120 }
    expect(notification.valid?).to be(true)
  end

  it 'allows the size of payload under 5 KB' do
    allow(notification).to receive(:payload_data_size) { 5119 }
    expect(notification.valid?).to be(true)
  end
end
