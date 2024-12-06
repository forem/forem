require 'spec_helper'

shared_examples 'PaymentIntent API' do

  it "creates a succeeded stripe payment_intent" do
    payment_intent = Stripe::PaymentIntent.create(amount:  100, currency: "usd")

    expect(payment_intent.id).to match(/^test_pi/)
    expect(payment_intent.amount).to eq(100)
    expect(payment_intent.currency).to eq('usd')
    expect(payment_intent.metadata.to_hash).to eq({})
    expect(payment_intent.status).to eq('succeeded')
  end

  it "creates a requires_action stripe payment_intent when amount matches 3184" do
    payment_intent = Stripe::PaymentIntent.create(amount:  3184, currency: "usd")

    expect(payment_intent.id).to match(/^test_pi/)
    expect(payment_intent.amount).to eq(3184)
    expect(payment_intent.currency).to eq('usd')
    expect(payment_intent.metadata.to_hash).to eq({})
    expect(payment_intent.status).to eq('requires_action')
    expect(payment_intent.next_action.type).to eq('use_stripe_sdk')
  end

  it "creates a requires_payment_method stripe payment_intent when amount matches 3184" do
    payment_intent = Stripe::PaymentIntent.create(amount: 3178, currency: "usd")

    expect(payment_intent.id).to match(/^test_pi/)
    expect(payment_intent.amount).to eq(3178)
    expect(payment_intent.currency).to eq('usd')
    expect(payment_intent.metadata.to_hash).to eq({})
    expect(payment_intent.status).to eq('requires_payment_method')
    expect(payment_intent.last_payment_error.code).to eq('card_declined')
    expect(payment_intent.last_payment_error.decline_code).to eq('insufficient_funds')
    expect(payment_intent.last_payment_error.message).to eq('Not enough funds.')
  end

  it "creates a requires_payment_method stripe payment_intent when amount matches 3055" do
    payment_intent = Stripe::PaymentIntent.create(amount: 3055, currency: "usd")

    expect(payment_intent.id).to match(/^test_pi/)
    expect(payment_intent.amount).to eq(3055)
    expect(payment_intent.currency).to eq('usd')
    expect(payment_intent.metadata.to_hash).to eq({})
    expect(payment_intent.status).to eq('requires_capture')
  end

  describe "listing payment_intent" do
    before do
      3.times do
        Stripe::PaymentIntent.create(amount: 100, currency: "usd")
      end
    end

    it "without params retrieves all stripe payment_intent" do
      expect(Stripe::PaymentIntent.list.count).to eq(3)
    end

    it "accepts a limit param" do
      expect(Stripe::PaymentIntent.list(limit: 2).count).to eq(2)
    end
  end

  it "retrieves a stripe payment_intent" do
    original = Stripe::PaymentIntent.create(amount:  100, currency: "usd")
    payment_intent = Stripe::PaymentIntent.retrieve(original.id)

    expect(payment_intent.id).to eq(original.id)
    expect(payment_intent.amount).to eq(original.amount)
    expect(payment_intent.currency).to eq(original.currency)
    expect(payment_intent.metadata.to_hash).to eq(original.metadata.to_hash)
  end

  it "cannot retrieve a payment_intent that doesn't exist" do
    expect { Stripe::PaymentIntent.retrieve('nope') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('payment_intent')
      expect(e.http_status).to eq(404)
    }
  end

  it 'creates and confirms a stripe payment_intent with confirm flag to true' do
    payment_intent = Stripe::PaymentIntent.create(
      amount: 100, currency: 'usd', confirm: true
    )
    expect(payment_intent.status).to eq('succeeded')
    expect(payment_intent.charges.data.size).to eq(1)
    expect(payment_intent.charges.data.first.object).to eq('charge')
    balance_txn = payment_intent.charges.data.first.balance_transaction
    expect(balance_txn).to match(/^test_txn/)
    expect(Stripe::BalanceTransaction.retrieve(balance_txn).id).to eq(balance_txn)
  end

  it "confirms a stripe payment_intent" do
    payment_intent = Stripe::PaymentIntent.create(amount: 100, currency: "usd")
    confirmed_payment_intent = payment_intent.confirm()
    expect(confirmed_payment_intent.status).to eq("succeeded")
    expect(confirmed_payment_intent.charges.data.size).to eq(1)
    expect(confirmed_payment_intent.charges.data.first.object).to eq('charge')
  end

  it "captures a stripe payment_intent" do
    payment_intent = Stripe::PaymentIntent.create(amount: 100, currency: "usd")
    confirmed_payment_intent = payment_intent.capture()
    expect(confirmed_payment_intent.status).to eq("succeeded")
    expect(confirmed_payment_intent.charges.data.size).to eq(1)
    expect(confirmed_payment_intent.charges.data.first.object).to eq('charge')
  end

  it "cancels a stripe payment_intent" do
    payment_intent = Stripe::PaymentIntent.create(amount: 100, currency: "usd")
    confirmed_payment_intent = payment_intent.cancel()
    expect(confirmed_payment_intent.status).to eq("canceled")
  end

  it "updates a stripe payment_intent" do
    original = Stripe::PaymentIntent.create(amount: 100, currency: "usd")
    payment_intent = Stripe::PaymentIntent.retrieve(original.id)

    payment_intent.amount = 200
    payment_intent.save

    updated = Stripe::PaymentIntent.retrieve(original.id)

    expect(updated.amount).to eq(200)
  end

  it 'when amount is not integer', live: true do
    expect { Stripe::PaymentIntent.create(amount: 400.2,
                                         currency: 'usd') }.to raise_error { |e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('amount')
      expect(e.http_status).to eq(400)
    }
  end

  it 'when amount is negative', live: true do
    expect { Stripe::PaymentIntent.create(amount: -400,
                                     currency: 'usd') }.to raise_error { |e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('amount')
      expect(e.message).to match(/^Invalid.*integer/)
      expect(e.http_status).to eq(400)
    }
  end
end
