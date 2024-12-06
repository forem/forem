require 'unit_spec_helper'

describe Rpush::Client::Redis::Wns::RawNotification do
  it_behaves_like 'Rpush::Client::Wns::RawNotification'

  subject(:notification) do
    notif = described_class.new
    notif.app = Rpush::Wns::App.create!(name: "MyApp", client_id: "someclient", client_secret: "somesecret")
    notif.uri = 'https://db5.notify.windows.com/?token=TOKEN'
    notif.data = { foo: 'foo', bar: 'bar' }
    notif
  end

  # This fails because the length validation is only on active record
  # Attempting to move to active model in rails 6 fails
  # because wns_notification#as_json is not defined
  # and the active_model#as_json version results in a stack level too deep error
  xit 'does not allow the size of payload over 5 KB' do
    allow(notification).to receive(:payload_data_size) { 5121 }
    expect(notification.valid?).to be(false)
  end
end if redis?
