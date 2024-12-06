require 'unit_spec_helper'

shared_examples 'Rpush::Client::Adm::Notification' do
  let(:app) { Rpush::Adm::App.create!(name: 'test', client_id: 'CLIENT_ID', client_secret: 'CLIENT_SECRET') }
  let(:notification) { described_class.new }

  it "has a 'data' payload limit of 6144 bytes" do
    notification.data = { key: "a" * 6144 }
    expect(notification.valid?).to eq(false)
    expect(notification.errors[:base]).to eq ["Notification payload data cannot be larger than 6144 bytes."]
  end

  it 'limits the number of registration ids to 100' do
    notification.registration_ids = ['a'] * (100 + 1)
    expect(notification.valid?).to eq(false)
    expect(notification.errors[:base]).to eq ["Number of registration_ids cannot be larger than 100."]
  end

  it 'validates data can be blank if collapse_key is set' do
    notification.app = app
    notification.registration_ids = ['a']
    notification.collapse_key = 'test'
    notification.data = nil
    expect(notification.valid?).to eq(true)
    expect(notification.errors[:data]).to be_empty
  end

  it 'validates data is present if collapse_key is not set' do
    notification.collapse_key = nil
    notification.data = nil
    expect(notification.valid?).to eq(false)
    expect(notification.errors[:data]).to eq ['must be set unless collapse_key is specified']
  end

  it 'includes expiresAfter in the payload' do
    notification.expiry = 100
    expect(notification.as_json['expiresAfter']).to eq 100
  end
end
