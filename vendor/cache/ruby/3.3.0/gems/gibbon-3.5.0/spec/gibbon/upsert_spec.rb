require 'spec_helper'
require 'webmock/rspec'
require 'digest/md5'

describe Gibbon do
  let(:api_key) { '1234-us1' }
  let(:list_id) { 'testlist' }
  let(:email) { 'john.doe@example.com' }
  let(:member_id) { Digest::MD5.hexdigest(email) }

  let(:request_body) do
    {
      email_address: email,
      status: 'subscribed',
      merge_fields: {FNAME: 'John', LNAME: 'Doe'}
    }
  end

  it 'supports upsert request' do
    stub_request(:put, "https://us1.api.mailchimp.com/3.0/lists/#{list_id}/members/#{member_id}")
      .with(body: MultiJson.dump(request_body), basic_auth: ['apikey', '1234-us1'])
      .to_return(status: 200)

    Gibbon::Request.new(api_key: api_key)
      .lists(list_id).members(member_id)
      .upsert(body: request_body)
  end
end
