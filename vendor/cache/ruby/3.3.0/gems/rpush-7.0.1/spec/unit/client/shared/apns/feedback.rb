require 'unit_spec_helper'

shared_examples 'Rpush::Client::Apns::Feedback' do
  it 'validates the format of the device_token' do
    notification = described_class.new(device_token: "{$%^&*()}")
    expect(notification.valid?).to be_falsey
    expect(notification.errors[:device_token]).to include('is invalid')
  end
end
