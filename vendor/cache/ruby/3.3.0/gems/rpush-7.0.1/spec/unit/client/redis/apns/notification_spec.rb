# encoding: US-ASCII

require "unit_spec_helper"

describe Rpush::Client::Redis::Apns::Notification do
  it_behaves_like 'Rpush::Client::Apns::Notification'

  it "should validate the length of the binary conversion of the notification" do
    notification = described_class.new
    notification.app = Rpush::Apns2::App.create(name: 'test', environment: 'development', certificate: TEST_CERT)
    notification.device_token = "a" * 108
    notification.alert = ""

    notification.alert << "a" until notification.payload.bytesize == 2048
    expect(notification.valid?).to be_truthy
    expect(notification.errors[:base]).to be_empty

    notification.alert << "a"
    expect(notification.valid?).to be_falsey
    expect(notification.errors[:base].include?("APN notification cannot be larger than 2048 bytes. Try condensing your alert and device attributes.")).to be_truthy
  end

  it "should default the sound to 'default'" do
    notification = described_class.new
    expect(notification.sound).to eq('default')
  end

  # skipping these tests because data= for redis doesn't merge existing data
  xit 'does not overwrite the mutable-content flag when setting attributes for the device' do
    notification.mutable_content = true
    notification.data = { 'hi' => 'mom' }
    expect(notification.as_json['aps']['mutable-content']).to eq 1
    expect(notification.as_json['hi']).to eq 'mom'
  end

  xit 'does not overwrite the content-available flag when setting attributes for the device' do
    notification.content_available = true
    notification.data = { 'hi' => 'mom' }
    expect(notification.as_json['aps']['content-available']).to eq 1
    expect(notification.as_json['hi']).to eq 'mom'
  end

  # redis does not use alert_is_json - unclear if that is a bug or desired behavior
  xit 'does confuse a JSON looking string as JSON if the alert_is_json attribute is not present' do
    notification = described_class.new
    allow(notification).to receive_messages(has_attribute?: false)
    notification.alert = "{\"one\":2}"
    expect(notification.alert).to eq('one' => 2)
  end
end if redis?
