require_relative '../test_helper'

describe Fastly::Syslog do

  let(:client)     { Fastly.new(api_key: 'notasecrettestkey', user: 'test@example.com', password: 'password') }
  let(:service_id) { SecureRandom.hex(6) }
  let(:version)    { 1 }
  let(:syslog) { Fastly::Syslog.new({ name: 'test_syslog', service_id: service_id, version: 1 }, client) }

  before {
    stub_request(:post, "#{Fastly::Client::DEFAULT_URL}/login").to_return(body: '{}', status: 200)
  }

  describe '#item' do
    it 'translates response_condition attribute properly' do
      response_condition = 'never_syslog'

      response_body = JSON.dump(
        'placement' => nil,
        'format_version' => '2',
        'hostname' => nil,
        'response_condition' => response_condition,
        'address' => '10.2.2.2',
        'public_key' => nil,
        'updated_at' => '2017-12-13T16:28:09Z',
        'message_type' => 'classic',
        'ipv4' => '10.2.2.2',
        'tls_hostname' => nil,
        'name' => syslog.name,
        'port' => '514',
        'use_tls' => '0',
        'service_id' => service_id,
        'tls_ca_cert' => nil,
        'token' => nil,
        'version' => version,
        'deleted_at' => nil,
        'created_at' => '2017-12-12T21:44:45Z',
        'format' => '%h %l %u %t \'%r\' %>s %b',
      )

      get_item_url = "#{Fastly::Client::DEFAULT_URL}/service/#{service_id}/version/#{version}/logging/syslog/#{syslog.name}"
      get_service_url = "#{Fastly::Client::DEFAULT_URL}/service/#{service_id}/version/#{version}"

      stub_request(:get, get_service_url).to_return(status: 200, body: '{}', headers: {})
      stub_request(:get, get_item_url).to_return(body: response_body, status: 200)

      item = client.get_syslog(service_id, version, syslog.name)
      assert_equal response_condition, item.response_condition
    end
  end
end
