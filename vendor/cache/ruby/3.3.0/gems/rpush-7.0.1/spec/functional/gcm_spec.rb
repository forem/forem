require 'functional_spec_helper'

describe 'GCM' do
  let(:app) { Rpush::Gcm::App.new }
  let(:notification) { Rpush::Gcm::Notification.new }
  let(:response) { double(Net::HTTPResponse, code: 200) }
  let(:http) { double(Net::HTTP::Persistent, request: response, shutdown: nil) }

  before do
    app.name = 'test'
    app.auth_key = 'abc123'
    app.save!

    notification.app_id = app.id
    notification.registration_ids = ['foo']
    notification.data = { message: 'test' }
    notification.save!

    allow(Net::HTTP::Persistent).to receive_messages(new: http)
  end

  it 'delivers a notification successfully' do
    allow(response).to receive_messages(body: JSON.dump(results: [{ message_id: notification.registration_ids.first.to_s }]))

    expect do
      Rpush.push
      notification.reload
    end.to change(notification, :delivered).to(true)
  end

  it 'fails to deliver a notification successfully' do
    allow(response).to receive_messages(body: JSON.dump(results: [{ error: 'Err' }]))
    Rpush.push
    notification.reload
    expect(notification.delivered).to eq(false)
  end

  it 'retries notification that fail due to a SocketError' do
    expect(http).to receive(:request).and_raise(SocketError.new)
    expect(notification.deliver_after).to be_nil
    expect do
      Rpush.push
      notification.reload
    end.to change(notification, :deliver_after).to(kind_of(Time))
  end
end
