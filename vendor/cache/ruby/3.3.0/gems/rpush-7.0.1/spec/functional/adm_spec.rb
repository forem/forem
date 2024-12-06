require 'functional_spec_helper'

describe 'ADM' do
  let(:app) { Rpush::Adm::App.new }
  let(:notification) { Rpush::Adm::Notification.new }
  let(:response) { double(Net::HTTPResponse, code: 200) }
  let(:http) { double(Net::HTTP::Persistent, request: response, shutdown: nil) }
  let(:delivered_ids) { [] }
  let(:failed_ids) { [] }
  let(:retry_ids) { [] }

  before do
    app.name = 'test'
    app.client_id = 'abc'
    app.client_secret = '123'
    app.save!

    notification.app = app
    notification.registration_ids = ['foo']
    notification.data = { message: 'test' }
    notification.save!

    allow(Net::HTTP::Persistent).to receive_messages(new: http)
  end

  it 'delivers a notification successfully' do
    allow(response).to receive_messages(body: JSON.dump(registrationID: notification.registration_ids.first.to_s))

    expect do
      Rpush.push
      notification.reload
    end.to change(notification, :delivered).to(true)
  end

  it 'fails to deliver a notification successfully' do
    allow(response).to receive_messages(code: 400, body: JSON.dump(reason: 'error', registrationID: notification.registration_ids.first.to_s))
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
