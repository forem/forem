require 'unit_spec_helper'

shared_examples 'Rpush::Client::Gcm::Notification' do
  let(:app) { Rpush::Gcm::App.create!(name: 'test', auth_key: 'abc') }
  let(:notification) { described_class.new }

  it "has a 'data' payload limit of 4096 bytes" do
    notification.data = { key: "a" * 4096 }
    expect(notification.valid?).to be_falsey
    expect(notification.errors[:base]).to eq ["Notification payload data cannot be larger than 4096 bytes."]
  end

  it 'limits the number of registration ids to 1000' do
    notification.registration_ids = ['a'] * (1000 + 1)
    expect(notification.valid?).to be_falsey
    expect(notification.errors[:base]).to eq ["Number of registration_ids cannot be larger than 1000."]
  end

  it 'validates expiry is present if collapse_key is set' do
    notification.collapse_key = 'test'
    notification.expiry = nil
    expect(notification.valid?).to be_falsey
    expect(notification.errors[:expiry]).to eq ['must be set when using a collapse_key']
  end

  it 'includes time_to_live in the payload' do
    notification.expiry = 100
    expect(notification.as_json['time_to_live']).to eq 100
  end

  it 'includes content_available in the payload' do
    notification.content_available = true
    expect(notification.as_json['content_available']).to eq true
  end

  it 'includes mutable_content in the payload' do
    notification.mutable_content = true
    expect(notification.as_json['mutable_content']).to eq true
  end

  it 'sets the priority to high when set to high' do
    notification.priority = 'high'
    expect(notification.as_json['priority']).to eq 'high'
  end

  it 'sets the priority to normal when set to normal' do
    notification.priority = 'normal'
    expect(notification.as_json['priority']).to eq 'normal'
  end

  it 'validates the priority is either "normal" or "high"' do
    notification.priority = 'invalid'
    expect(notification.errors[:priority]).to eq ['must be one of either "normal" or "high"']
  end

  it 'excludes the priority if it is not defined' do
    expect(notification.as_json).not_to have_key 'priority'
  end

  it 'includes the notification payload if defined' do
    notification.notification = { key: 'any key is allowed' }
    expect(notification.as_json).to have_key 'notification'
  end

  it 'excludes the notification payload if undefined' do
    expect(notification.as_json).not_to have_key 'notification'
  end

  it 'includes the dry_run payload if defined' do
    notification.dry_run = true
    expect(notification.as_json['dry_run']).to eq true
  end

  it 'excludes the dry_run payload if undefined' do
    expect(notification.as_json).not_to have_key 'dry_run'
  end
end
