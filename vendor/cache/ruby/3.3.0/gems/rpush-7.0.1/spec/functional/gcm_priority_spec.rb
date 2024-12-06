require 'functional_spec_helper'

describe 'GCM priority' do
  let(:app) { Rpush::Gcm::App.new }
  let(:notification) { Rpush::Gcm::Notification.new }
  let(:hydrated_notification) { Rpush::Gcm::Notification.find(notification.id) }
  let(:response) { double(Net::HTTPResponse, code: 200) }
  let(:http) { double(Net::HTTP::Persistent, request: response, shutdown: nil) }
  let(:priority) { 'normal' }

  before do
    app.name = 'test'
    app.auth_key = 'abc123'
    app.save!

    notification.app_id = app.id
    notification.registration_ids = ['foo']
    notification.data = { message: 'test' }
    notification.priority = priority
    notification.save!

    allow(Net::HTTP::Persistent).to receive_messages(new: http)
  end

  it 'supports normal priority' do
    expect(hydrated_notification.as_json['priority']).to eq('normal')
  end

  context 'high priority' do
    let(:priority) { 'high' }

    it 'supports high priority' do
      expect(hydrated_notification.as_json['priority']).to eq('high')
    end
  end

  it 'does not add an error when receiving expected priority' do
    expect(hydrated_notification.errors.messages[:priority]).to be_empty
  end
end
