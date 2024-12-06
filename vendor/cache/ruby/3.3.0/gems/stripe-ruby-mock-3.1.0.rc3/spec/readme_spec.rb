require 'stripe_mock'

describe 'README examples' do
  let(:stripe_helper) { StripeMock.create_test_helper }

  before { StripeMock.start }
  after  { StripeMock.stop }

  it "creates a stripe customer" do

    # This doesn't touch stripe's servers nor the internet!
    customer = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      card: stripe_helper.generate_card_token
    })
    expect(customer.email).to eq('johnny@appleseed.com')
  end


  it "mocks a declined card error" do
    # Prepares an error for the next create charge request
    StripeMock.prepare_card_error(:card_declined)

    expect { Stripe::Charge.create(amount: 1, currency: 'usd') }.to raise_error {|e|
      expect(e).to be_a Stripe::CardError
      expect(e.http_status).to eq(402)
      expect(e.code).to eq('card_declined')
      expect(e.json_body[:error][:decline_code]).to eq('do_not_honor')
    }
  end

  it "has built-in card errors" do
    StripeMock.prepare_card_error(:incorrect_number)
    StripeMock.prepare_card_error(:invalid_number)
    StripeMock.prepare_card_error(:invalid_expiry_month)
    StripeMock.prepare_card_error(:invalid_expiry_year)
    StripeMock.prepare_card_error(:invalid_cvc)
    StripeMock.prepare_card_error(:expired_card)
    StripeMock.prepare_card_error(:incorrect_cvc)
    StripeMock.prepare_card_error(:card_declined)
    StripeMock.prepare_card_error(:missing)
    StripeMock.prepare_card_error(:processing_error)
  end

  it "mocks a stripe webhook" do
    event = StripeMock.mock_webhook_event('customer.created')

    customer_object = event.data.object
    expect(customer_object.id).to_not be_nil
    expect(customer_object.default_card).to_not be_nil
    # etc.
  end

  it "can override default webhook values" do
    event = StripeMock.mock_webhook_event('customer.created', {
      :id => 'cus_my_custom_value',
      :email => 'joe@example.com'
    })
    # Alternatively:
    # event.data.object.id = 'cus_my_custom_value'
    # event.data.object.email = 'joe@example.com'
    expect(event.data.object.id).to eq('cus_my_custom_value')
    expect(event.data.object.email).to eq('joe@example.com')
  end

  it "generates a stripe card token" do
    card_token = StripeMock.generate_card_token(last4: "9191", exp_year: 1984)

    cus = Stripe::Customer.create(source: card_token)
    card = cus.sources.data.first
    expect(card.last4).to eq("9191")
    expect(card.exp_year).to eq(1984)
  end

end
