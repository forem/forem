require 'unit_spec_helper'

shared_examples 'Rpush::Client::Wns::BadgeNotification' do
  let(:notification) do
    notif = described_class.new
    notif.app  = Rpush::Wns::App.create!(name: "MyApp", client_id: "someclient", client_secret: "somesecret")
    notif.uri  = 'https://db5.notify.windows.com/?token=TOKEN'
    notif.badge = 42
    notif
  end

  it 'should allow a notification without data' do
    expect(notification.valid?).to be(true)
  end
end
