require 'functional_spec_helper'

describe 'Pushy' do
  let(:external_device_id) { '5a622ae5813e2875bfdbe496' }
  let(:response) { instance_double('Net::HTTPResponse', code: 200, body: { id: external_device_id }.to_json) }
  let(:http) { instance_double('Net::HTTP::Persistent', request: response, shutdown: nil) }
  let(:app) { Rpush::Pushy::App.create!(name: 'MyApp', api_key: 'my_api_key') }

  let(:notification) do
    Rpush::Pushy::Notification.create!(app: app, data: { message: 'test' }, registration_ids: ['id'])
  end

  before do
    allow(Net::HTTP::Persistent).to receive_messages(new: http)
  end

  it 'deliveres a notification successfully' do
    expect { Rpush.push }.to change { notification.reload.delivered }.to(true)
  end

  it { expect { Rpush.push }.to change { notification.reload.external_device_id }.to(external_device_id) }
end
