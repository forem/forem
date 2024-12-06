require 'spec_helper'

shared_examples 'Checkout API' do

  it "creates a stripe checkout session" do
    session = Stripe::Checkout::Session.create({
      payment_method_types: ['card'],
      line_items: [{
        name: 'T-shirt',
        quantity: 1,
        amount: 500,
        currency: 'usd',
      }],
    })
    expect(session.id).to match(/^test_cs/)
    expect(session.line_items.count).to eq(1)
  end

  context 'retrieve a checkout session' do
    let(:checkout_session1) { stripe_helper.create_checkout_session }

    it 'ca be retrieved by id' do
      checkout_session1

      checkout_session = Stripe::Checkout::Session.retrieve(checkout_session1.id)

      expect(checkout_session.id).to eq(checkout_session1.id)
    end

    it "cannot retrieve a checkout session that doesn't exist" do
      expect { Stripe::Checkout::Session.retrieve('nope') }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.param).to eq('checkout_session')
        expect(e.http_status).to eq(404)
      }
    end

    it 'can expand setup_intent' do
      setup_intent = Stripe::SetupIntent.create
      initial_session = Stripe::Checkout::Session.create(setup_intent: setup_intent.id)

      checkout_session = Stripe::Checkout::Session.retrieve(id: initial_session.id, expand: ['setup_intent'])

      expect(checkout_session.setup_intent).to eq(setup_intent)
    end
  end
end
