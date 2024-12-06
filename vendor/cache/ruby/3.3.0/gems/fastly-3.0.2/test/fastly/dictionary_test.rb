require_relative '../test_helper'

describe Fastly::Dictionary do

  let(:client)     { Fastly.new(api_key: 'notasecrettestkey') }
  let(:service_id) { SecureRandom.hex(6) }
  let(:version)    {  1 }
  let(:dictionary) { Fastly::Dictionary.new({id: SecureRandom.hex(6), service_id: service_id, version: 1}, client) }

  before {
    stub_request(:post, "#{Fastly::Client::DEFAULT_URL}/login").to_return(body: '{}', status: 200)
  }

  describe '#item' do
    it 'returns the nil when item is not present' do
      item_key   = 'key'
      get_item_url = "#{Fastly::Client::DEFAULT_URL}/service/#{service_id}/dictionary/#{dictionary.id}/item/#{item_key}"

      response_body = JSON.dump(
        "msg"    => "Record not found",
        "detail" => "Couldn't find dictionary item '{ service => #{service_id}, dictionary_id => #{dictionary.id}, item_key => #{item_key}, deleted => 0000-00-00 00:00:00'",
      )

      stub_request(:get, get_item_url).to_return(body: response_body, status: 404)

      assert_nil dictionary.item('key')
    end

    it 'returns the corresponding dictionary item when present' do
      item_key   = 'key'
      item_value = 'value'

      response_body = JSON.dump(
        "dictionary_id" => dictionary.id,
        "service_id"    => service_id,
        "item_key"      => item_key,
        "item_value"    => item_value,
        "created_at"    => "2016-04-21T18:14:32+00:00",
        "deleted_at"    => nil,
        "updated_at"    => "2016-04-21T18:14:32+00:00",
      )

      get_item_url = "#{Fastly::Client::DEFAULT_URL}/service/#{service_id}/dictionary/#{dictionary.id}/item/#{item_key}"

      stub_request(:get, get_item_url).to_return(body: response_body, status: 200)

      item = dictionary.item('key')

      assert_equal item_key, item.key
      assert_equal item_value, item.value
    end
  end
end
