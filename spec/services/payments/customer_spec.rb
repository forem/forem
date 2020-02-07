require "rails_helper"

RSpec.describe Payments::Customer, type: :service do
  before do
    StripeMock.start
  end

  after do
    StripeMock.stop
  end

  describe ".get" do
    it "retrieves an existing customer" do
      customer = Stripe::Customer.create
      expect(described_class.get(customer.id)).to be_present
    end

    it "raises Payments::CustomerNotFoundError if the customer does not exist" do
      expect { described_class.get("foobar") }.to raise_error(Payments::InvalidRequestError)
    end

    it "raises Payments::PaymentsError for any other known error" do
      allow(Stripe::Customer).to receive(:retrieve).with("foobar").and_raise(Stripe::StripeError)
      expect { described_class.get("foobar") }.to raise_error(Payments::PaymentsError)
    end
  end

  describe ".create" do
    it "creates a new customer" do
      expect(described_class.create).to be_present
    end

    it "raises an error if anything in the params is invalid" do
      error = Stripe::InvalidRequestError.new("message", :email)
      allow(Stripe::Customer).to receive(:create).and_raise(error)
      expect { described_class.create(email: "foobar") }.to raise_error(Payments::InvalidRequestError)
    end

    it "raises Payments::PaymentsError for any other known error" do
      allow(Stripe::Customer).to receive(:create).with(email: "foobar").
        and_raise(Stripe::StripeError)
      expect { described_class.create(email: "foobar") }.to raise_error(Payments::PaymentsError)
    end
  end

  describe ".create_source" do
    it "creates a new source" do
      customer = Stripe::Customer.create
      expect(described_class.create_source(customer.id, "token")).to be_present
    end

    it "raises an error if anything in the params is invalid" do
      error = Stripe::InvalidRequestError.new("message", :token)
      allow(Stripe::Customer).to receive(:create_source).and_raise(error)
      expect { described_class.create_source("customer_id", "token") }.to raise_error(Payments::InvalidRequestError)
    end

    it "raises Payments::PaymentsError for any other known error" do
      allow(Stripe::Customer).to receive(:create_source).and_raise(Stripe::StripeError)
      expect { described_class.create_source("customer_id", "token") }.to raise_error(Payments::PaymentsError)
    end
  end

  describe ".charge" do
    let(:stripe_helper) { StripeMock.create_test_helper }

    it "charges a customer" do
      customer = Stripe::Customer.create
      charge = described_class.charge(customer: customer, amount: 1, description: "Test charge")
      expect(charge).to be_present
    end

    it "charges a customer with an explicit card id" do
      customer = Stripe::Customer.create
      token = stripe_helper.generate_card_token
      card = Stripe::Customer.create_source(customer.id, source: token)
      charge = described_class.charge(
        customer: customer, amount: 1, description: "Test charge", card_id: card.id,
      )
      expect(charge).to be_present
    end

    it "raises a card error if the card has any troubles" do
      StripeMock.prepare_card_error(:expired_card)

      customer = Stripe::Customer.create
      token = stripe_helper.generate_card_token
      card = Stripe::Customer.create_source(customer.id, source: token)

      expect do
        described_class.charge(
          customer: customer, amount: 1, description: "Test charge", card_id: card.id,
        )
      end.to raise_error(Payments::CardError)
    end
  end
end
