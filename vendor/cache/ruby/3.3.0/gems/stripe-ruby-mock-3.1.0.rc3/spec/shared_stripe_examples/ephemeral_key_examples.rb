require 'spec_helper'

shared_examples 'EphemeralKey API' do
  describe 'Create a new key' do
    let(:customer)  { Stripe::Customer.create email: 'test@example.com' }
    let(:version) { '2016-07-06' }

    it 'creates a new key' do
      key = Stripe::EphemeralKey.create(
        { customer: customer.id },
        { stripe_version: version }
      )

      expect(key[:associated_objects][0][:id]).to eq customer.id
    end
  end
end
