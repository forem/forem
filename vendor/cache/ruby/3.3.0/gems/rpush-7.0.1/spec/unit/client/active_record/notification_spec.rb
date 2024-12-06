require 'unit_spec_helper'

describe Rpush::Client::ActiveRecord::Notification do
  it_behaves_like 'Rpush::Client::Notification'

  subject(:notification) { described_class.new }

  it 'saves its parent App if required' do
    notification.app = Rpush::App.new(name: "aname")
    expect(notification.app).to be_valid
    expect(notification).to be_valid
  end

  it 'does not mix notification and data payloads' do
    notification.data = { key: 'this is data' }
    notification.notification = { key: 'this is notification' }
    expect(notification.data).to eq('key' => 'this is data')
    expect(notification.notification).to eq('key' => 'this is notification')
  end
end if active_record?
