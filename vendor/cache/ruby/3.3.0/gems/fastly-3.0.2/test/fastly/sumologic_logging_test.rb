require_relative '../test_helper'

describe Fastly::SumologicLogging do
  let(:client)     { Fastly.new(api_key: 'notasecrettestkey', user: 'test@example.com', password: 'password') }
  let(:service_id) { SecureRandom.hex(6) }
  let(:version)    { 1 }
  let(:sumo) { Fastly::SumologicLogging.new({ name: 'test_syslog', service_id: service_id, version: 1 }, client) }

  before do
    stub_request(:post, "#{Fastly::Client::DEFAULT_URL}/login").to_return(body: '{}', status: 200)
  end

  describe '#list' do
    it 'lists sumologic endpoints' do
      response_body = JSON.dump(
        [
          {
            'created_at'         => '2020-07-15T19:34:48Z',
            'format_version'     => '2',
            'message_type'       => 'blank',
            'placement'          => 'none',
            'response_condition' => '',
            'deleted_at'         => nil,
            'version'            => '74',
            'url'                => 'https://endpoint1.collection.us2.sumologic.com/stuff',
            'updated_at'         => '2021-06-15T21:56:35Z',
            'format'             => 'fake',
            'name'               => 'Sumo Logic',
            'service_id'         => service_id
          }
        ]
      )

      list_url = "#{Fastly::Client::DEFAULT_URL}/service/#{service_id}/version/#{version}/#{Fastly::SumologicLogging.path}"
      stub_request(:get, list_url).to_return(body: response_body, status: 200)

      get_service_url = "#{Fastly::Client::DEFAULT_URL}/service/#{service_id}/version/#{version}"
      stub_request(:get, get_service_url).to_return(status: 200, body: '{}', headers: {})

      sumos = client.list_sumologic_loggings(service_id: service_id, version: version)
      assert_equal sumos.map {|s| [s.name, s.format]}, [['Sumo Logic', 'fake']]
    end
  end
end
