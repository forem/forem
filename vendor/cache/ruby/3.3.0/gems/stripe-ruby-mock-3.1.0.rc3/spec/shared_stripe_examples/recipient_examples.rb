require 'spec_helper'

shared_examples 'Recipient API' do

  it "creates a stripe recipient with a default bank and card", skip: 'Stripe has deprecated Recipients' do
    recipient = Stripe::Recipient.create({
      type:  "corporation",
      name: "MyCo",
      email: "owner@myco.com",
      bank_account: 'void_bank_token',
      card: stripe_helper.generate_card_token
    })
    expect(recipient.id).to match /^test_rp/
    expect(recipient.type).to eq('corporation')
    expect(recipient.name).to eq('MyCo')
    expect(recipient.email).to eq('owner@myco.com')
    expect(recipient.default_card).to_not be_nil

    expect(recipient.active_account).to_not be_nil
    expect(recipient.active_account.bank_name).to_not be_nil
    expect(recipient.active_account.last4).to_not be_nil

    expect(recipient.cards.count).to eq(1)
    expect(recipient.cards.data.length).to eq(1)
    expect(recipient.default_card).to_not be_nil
    expect(recipient.default_card).to eq recipient.cards.data.first.id

    expect { recipient.card }.to raise_error
  end

  it "raises a error if params are invalid", skip: 'Stripe has deprecated Recipients' do
    expect { Stripe::Recipient.create(name: "foo") }.to raise_error
    expect { Stripe::Recipient.create(type: "individual") }.to raise_error
    expect { Stripe::Recipient.create(name: "foo", type: "bar") }.to raise_error
    expect { Stripe::Recipient.create(name: "foo", type: "individual") }.not_to raise_error
  end

  it "creates a stripe recipient without a card", skip: 'Stripe has deprecated Recipients' do
    recipient = Stripe::Recipient.create({
      type:  "corporation",
      name: "MyCo",
      email: "cardless@appleseed.com"
    })
    expect(recipient.id).to match(/^test_rp/)
    expect(recipient.type).to eq('corporation')
    expect(recipient.name).to eq('MyCo')
    expect(recipient.email).to eq('cardless@appleseed.com')

    expect(recipient.cards.count).to eq(0)
    expect(recipient.cards.data.length).to eq(0)
    expect(recipient.default_card).to be_nil
  end

  it "stores a created stripe recipient in memory", skip: 'Stripe has deprecated Recipients' do
    recipient = Stripe::Recipient.create({
      type:  "individual",
      name: "Customer One",
      bank_account: 'bank_account_token_1',
      card: stripe_helper.generate_card_token
    })
    recipient2 = Stripe::Recipient.create({
      type:  "individual",
      name: "Customer Two",
      bank_account: 'bank_account_token_1',
      card: stripe_helper.generate_card_token
    })
    data = test_data_source(:recipients)
    expect(data[recipient.id]).to_not be_nil
    expect(data[recipient.id][:type]).to eq("individual")
    expect(data[recipient.id][:name]).to eq("Customer One")
    expect(data[recipient.id][:default_card]).to_not be_nil

    expect(data[recipient2.id]).to_not be_nil
    expect(data[recipient2.id][:type]).to eq("individual")
    expect(data[recipient2.id][:name]).to eq("Customer Two")
    expect(data[recipient2.id][:default_card]).to_not be_nil
  end

  it "retrieves a stripe recipient", skip: 'Stripe has deprecated Recipients' do
    original = Stripe::Recipient.create({
      type:  "individual",
      name: "Bob",
      email: "bob@example.com",
      card: stripe_helper.generate_card_token
    })
    recipient = Stripe::Recipient.retrieve(original.id)

    expect(recipient.id).to eq(original.id)
    expect(recipient.type).to eq(original.type)
    expect(recipient.name).to eq(original.name)
    expect(recipient.email).to eq(original.email)
    expect(recipient.default_card).to_not be_nil
  end

  it "cannot retrieve a recipient that doesn't exist", skip: 'Stripe has deprecated Recipients' do
    expect { Stripe::Recipient.retrieve('nope') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('recipient')
      expect(e.http_status).to eq(404)
    }
  end

  describe "Errors", :live => true, skip: 'Stripe has deprecated Recipients' do
    it "throws an error when the customer does not have the retrieving card id" do
      recipient = Stripe::Recipient.create(:name => "Bob Bobber", :type => "individual")
      card_id = "card_123"
      expect { recipient.cards.retrieve(card_id) }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.message).to include "Recipient", recipient.id, "does not have", card_id
        expect(e.param).to eq 'card'
        expect(e.http_status).to eq 404
      }
    end

    it "throws an error when the name does not have both first and last"
  end

end
