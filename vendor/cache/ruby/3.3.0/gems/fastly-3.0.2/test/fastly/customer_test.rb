require_relative '../test_helper'

describe Fastly::Customer do

  let(:fastly)      { Fastly.new(api_key: 'secret') }
  let(:customer_id) { SecureRandom.hex(6) }
  let(:owner_id)    { SecureRandom.hex(6) }

  let(:customer) do
    stub_request(:post, "#{Fastly::Client::DEFAULT_URL}/login").to_return(body: '{}', status: 200)

    customer_body = JSON.dump(
      'id' => customer_id,
      'owner_id' => owner_id,
      'legal_contact_id' => owner_id,
    )
    stub_request(:get, "#{Fastly::Client::DEFAULT_URL}/customer/#{customer_id}").to_return(body: customer_body, status: 200)

    owner_body = JSON.dump(
      'id' => owner_id,
      'name' => 'Sugar Watkins',
    )
    stub_request(:get, "#{Fastly::Client::DEFAULT_URL}/user/#{owner_id}").to_return(body: owner_body, status: 200)

    fastly.get_customer(customer_id)
  end

  describe '#legal_contact' do
    it 'returns the legal contact as a Fastly::User' do
      assert customer.legal_contact.is_a?(Fastly::User)
      assert_equal 'Sugar Watkins', customer.legal_contact.name
    end
  end

  describe '#owner' do
    it 'returns the owner as a Fastly::User' do
      assert customer.owner.is_a?(Fastly::User)
      assert_equal 'Sugar Watkins', customer.owner.name
    end
  end

  describe '#technical_contact' do
    it 'returns nil when the customer has no technical contact' do
      assert_nil customer.technical_contact_id
      assert_nil customer.technical_contact
    end
  end
end
