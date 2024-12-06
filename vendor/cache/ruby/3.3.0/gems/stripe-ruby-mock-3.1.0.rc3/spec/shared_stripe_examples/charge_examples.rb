require 'spec_helper'

shared_examples 'Charge API' do

  it "requires a valid card token", :live => true do
    expect {
      charge = Stripe::Charge.create(
        amount: 99,
        currency: 'usd',
        source: 'bogus_card_token'
      )
    }.to raise_error(Stripe::InvalidRequestError, /token/i)
  end

  it "requires a valid customer or source", :live => true do
    expect {
      charge = Stripe::Charge.create(
        amount: 99,
        currency: 'usd',
      )
    }.to raise_error(Stripe::InvalidRequestError, /Must provide source or customer/i)
  end

  it "requires presence of amount", :live => true do
    expect {
      charge = Stripe::Charge.create(
        currency: 'usd',
        source: stripe_helper.generate_card_token
      )
    }.to raise_error(Stripe::InvalidRequestError, /missing required param: amount/i)
  end

  it "requires presence of currency", :live => true do
    expect {
      charge = Stripe::Charge.create(
        amount: 99,
        source: stripe_helper.generate_card_token
      )
    }.to raise_error(Stripe::InvalidRequestError, /missing required param: currency/i)
  end

  it "requires a valid positive amount", :live => true do
    expect {
      charge = Stripe::Charge.create(
        amount: -99,
        currency: 'usd',
        source: stripe_helper.generate_card_token
      )
    }.to raise_error(Stripe::InvalidRequestError, /invalid positive integer/i)
  end

  it "requires a valid integer amount", :live => true do
    expect {
      charge = Stripe::Charge.create(
        amount: 99.0,
        currency: 'usd',
        source: stripe_helper.generate_card_token
      )
    }.to raise_error(Stripe::InvalidRequestError, /invalid integer/i)
  end

  it "creates a stripe charge item with a card token" do
    charge = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      source: stripe_helper.generate_card_token,
      description: 'card charge'
    )

    expect(charge.id).to match(/^test_ch/)
    expect(charge.amount).to eq(999)
    expect(charge.description).to eq('card charge')
    expect(charge.captured).to eq(true)
    expect(charge.status).to eq('succeeded')
  end

  it "creates a stripe charge item with a bank token" do
    charge = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      source: stripe_helper.generate_bank_token,
      description: 'bank charge'
    )

    expect(charge.id).to match(/^test_ch/)
    expect(charge.amount).to eq(999)
    expect(charge.description).to eq('bank charge')
    expect(charge.captured).to eq(true)
    expect(charge.status).to eq('succeeded')
  end

  it 'creates a stripe charge item with a customer', :live => true do
    customer = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      source: stripe_helper.generate_card_token(number: '4012888888881881', address_city: 'LA'),
      description: "a description"
    })

    expect(customer.sources.data.length).to eq(1)
    expect(customer.sources.data[0].id).not_to be_nil
    expect(customer.sources.data[0].last4).to eq('1881')

    charge = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      customer: customer.id,
      description: 'a charge with a specific customer'
    )

    expect(charge.id).to match(/^(test_)?ch/)
    expect(charge.amount).to eq(999)
    expect(charge.description).to eq('a charge with a specific customer')
    expect(charge.captured).to eq(true)
    expect(charge.source.last4).to eq('1881')
    expect(charge.source.address_city).to eq('LA')
  end

  it "creates a stripe charge item with a customer and card id" do
    customer = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      source: stripe_helper.generate_card_token(number: '4012888888881881'),
      description: "a description"
    })

    expect(customer.sources.data.length).to eq(1)
    expect(customer.sources.data[0].id).not_to be_nil
    expect(customer.sources.data[0].last4).to eq('1881')

    card   = customer.sources.data[0]
    charge = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      customer: customer.id,
      source: card.id,
      description: 'a charge with a specific card'
    )

    expect(charge.id).to match(/^test_ch/)
    expect(charge.amount).to eq(999)
    expect(charge.description).to eq('a charge with a specific card')
    expect(charge.captured).to eq(true)
    expect(charge.source.last4).to eq('1881')
  end


  it "stores a created stripe charge in memory" do
    charge = Stripe::Charge.create({
      amount: 333,
      currency: 'USD',
      source: stripe_helper.generate_card_token
    })
    charge2 = Stripe::Charge.create({
      amount: 777,
      currency: 'USD',
      source: stripe_helper.generate_card_token
    })
    data = test_data_source(:charges)
    expect(data[charge.id]).to_not be_nil
    expect(data[charge.id][:amount]).to eq(333)

    expect(data[charge2.id]).to_not be_nil
    expect(data[charge2.id][:amount]).to eq(777)
  end

  it "creates a balance transaction" do
    amount = 300
    fee = 10
    charge = Stripe::Charge.create({
      amount: amount,
      currency: 'USD',
      source: stripe_helper.generate_card_token,
      application_fee: fee,
    })
    bal_trans = Stripe::BalanceTransaction.retrieve(charge.balance_transaction)
    expect(bal_trans.amount).to eq(amount)
    expect(bal_trans.fee).to eq(39 + fee)
    expect(bal_trans.source).to eq(charge.id)
    expect(bal_trans.net).to eq(amount - bal_trans.fee)
  end

  context 'when conversion rate is set' do
    it "balance transaction stores amount converted from charge currency to USD" do
      StripeMock.set_conversion_rate(1.2)

      charge = Stripe::Charge.create({
        amount: 300,
        currency: 'CAD',
        source: stripe_helper.generate_card_token
      })
      bal_trans = Stripe::BalanceTransaction.retrieve(charge.balance_transaction)
      expect(bal_trans.amount).to eq(charge.amount * 1.2)
      expect(bal_trans.fee).to eq(39)
      expect(bal_trans.currency).to eq('usd')
    end
  end

  it "can expand balance transaction when creating a charge" do
    charge = Stripe::Charge.create({
      amount: 300,
      currency: 'USD',
      source: stripe_helper.generate_card_token,
      expand: ['balance_transaction']
    })
    expect(charge.balance_transaction).to be_a(Stripe::BalanceTransaction)
  end

  it "retrieves a stripe charge" do
    original = Stripe::Charge.create({
      amount: 777,
      currency: 'USD',
      source: stripe_helper.generate_card_token
    })
    charge = Stripe::Charge.retrieve(original.id)

    expect(charge.id).to eq(original.id)
    expect(charge.amount).to eq(original.amount)
  end

  it "can expand balance transaction when retrieving a charge" do
    original = Stripe::Charge.create({
      amount: 300,
      currency: 'USD',
      source: stripe_helper.generate_card_token
    })
    charge = Stripe::Charge.retrieve(
      id: original.id,
      expand: ['balance_transaction']
    )

    expect(charge.balance_transaction).to be_a(Stripe::BalanceTransaction)
  end

  it "cannot retrieve a charge that doesn't exist" do
    expect { Stripe::Charge.retrieve('nope') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('charge')
      expect(e.http_status).to eq(404)
    }
  end

  it "updates a stripe charge" do
    original = Stripe::Charge.create({
      amount: 777,
      currency: 'USD',
      source: stripe_helper.generate_card_token,
      description: 'Original description',
    })
    charge = Stripe::Charge.retrieve(original.id)

    charge.description = "Updated description"
    charge.metadata[:receipt_id] = 1234
    charge.receipt_email = "newemail@email.com"
    charge.fraud_details = {"user_report" => "safe"}
    charge.save

    updated = Stripe::Charge.retrieve(original.id)

    expect(updated.description).to eq(charge.description)
    expect(updated.metadata.to_hash).to eq(charge.metadata.to_hash)
    expect(updated.receipt_email).to eq(charge.receipt_email)
    expect(updated.fraud_details.to_hash).to eq(charge.fraud_details.to_hash)
  end

  it "updates a stripe charge with no changes" do
    original = Stripe::Charge.create({
      amount: 777,
      currency: 'USD',
      source: stripe_helper.generate_card_token,
      description: 'Original description',
      destination: {
        account: "acct_SOMEBOGUSID",
        amount: 150
      }
    })

    expect {
      updated = original.save
    }.not_to raise_error
  end

  it "does not lose data when updating a charge" do
    original = Stripe::Charge.create({
      amount: 777,
      currency: 'USD',
      source: stripe_helper.generate_card_token,
      metadata: {:foo => "bar"}
    })
    original.metadata[:receipt_id] = 1234
    original.save

    updated = Stripe::Charge.retrieve(original.id)

    expect(updated.metadata[:foo]).to eq "bar"
    expect(updated.metadata[:receipt_id]).to eq 1234
  end

  it "disallows most parameters on updating a stripe charge" do
    original = Stripe::Charge.create({
      amount: 777,
      currency: 'USD',
      source: stripe_helper.generate_card_token,
      description: 'Original description',
    })

    charge = Stripe::Charge.retrieve(original.id)
    charge.currency = "CAD"
    charge.amount = 777
    charge.source = {any: "source"}

    expect { charge.save }.to raise_error(Stripe::InvalidRequestError) do |error|
      expect(error.message).to match(/Received unknown parameters/)
      expect(error.message).to match(/currency/)
      expect(error.message).to match(/amount/)
      expect(error.message).to match(/source/)
    end
  end


  it "creates a unique balance transaction" do
    charge1 = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      source: stripe_helper.generate_card_token,
      description: 'card charge'
    )

    charge2 = Stripe::Charge.create(
      amount: 999,
      currency: 'USD',
      source: stripe_helper.generate_card_token,
      description: 'card charge'
    )

    expect(charge1.balance_transaction).not_to eq(charge2.balance_transaction)
  end

  context "retrieving a list of charges" do
    before do
      @customer = Stripe::Customer.create(email: 'johnny@appleseed.com')
      @customer2 = Stripe::Customer.create(email: 'johnny2@appleseed.com')
      @charge = Stripe::Charge.create(amount: 1, currency: 'usd', customer: @customer.id)
      @charge2 = Stripe::Charge.create(amount: 1, currency: 'usd', customer: @customer2.id)
    end

    it "stores charges for a customer in memory" do
      charges = Stripe::Charge.list(customer: @customer.id)
      expect(charges.map(&:id)).to eq([@charge.id])
    end

    it "stores all charges in memory" do
      expect(Stripe::Charge.list.data.map(&:id).reverse).to eq([@charge.id, @charge2.id])
    end

    it "defaults count to 10 charges" do
      11.times { Stripe::Charge.create(amount: 1, currency: 'usd', source: stripe_helper.generate_card_token) }

      expect(Stripe::Charge.list.data.count).to eq(10)
    end

    it "is marked as having more when more objects exist" do
      11.times { Stripe::Charge.create(amount: 1, currency: 'usd', source: stripe_helper.generate_card_token) }

      expect(Stripe::Charge.list.has_more).to eq(true)
    end

    context "when passing limit" do
      it "gets that many charges" do
        expect(Stripe::Charge.list(limit: 1).count).to eq(1)
      end
    end
  end

  it 'when use starting_after param', live: true do
    cus = Stripe::Customer.create(
        description: 'Customer for test@example.com',
        source: {
            object: 'card',
            number: '4242424242424242',
            exp_month: 12,
            exp_year: 2024,
            cvc: 123
        }
    )
    12.times do
      Stripe::Charge.create(customer: cus.id, amount: 100, currency: "usd")
    end

    all_charges = Stripe::Charge.list
    default_limit = 10
    half = Stripe::Charge.list(starting_after: all_charges.data.at(1).id)

    expect(half).to be_a(Stripe::ListObject)
    expect(half.data.count).to eq(default_limit)
    expect(half.data.first.id).to eq(all_charges.data.at(2).id)
  end


  describe 'captured status value' do
    it "reports captured by default" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        source: stripe_helper.generate_card_token
      })

      expect(charge.captured).to eq(true)
    end

    it "reports captured if capture requested" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        capture: true
      })

      expect(charge.captured).to eq(true)
    end

    it "reports not captured if capture: false requested" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        capture: false
      })

      expect(charge.captured).to eq(false)
    end
  end

  describe "two-step charge (auth, then capture)" do
    it "changes captured status upon #capture" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        capture: false
      })

      returned_charge = charge.capture
      expect(charge.captured).to eq(true)
      expect(returned_charge.id).to eq(charge.id)
      expect(returned_charge.captured).to eq(true)
    end

    it "captures with specified amount" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        capture: false
      })

      returned_charge = charge.capture({ amount: 677, application_fee: 123 })
      expect(charge.captured).to eq(true)
      expect(returned_charge.amount_refunded).to eq(100)
      expect(returned_charge.application_fee).to eq(123)
      expect(returned_charge.id).to eq(charge.id)
      expect(returned_charge.captured).to eq(true)
    end
  end

  describe "idempotency" do
    let(:customer) { Stripe::Customer.create(email: 'johnny@appleseed.com') }
    let(:charge_params) {{
      amount: 777,
      currency: 'USD',
      customer: customer.id,
      capture: true
    }}
    let(:charge_headers) {{
      idempotency_key: 'onceisenough'
    }}

    it "returns the original charge if the same idempotency_key is passed in" do
      charge1 = Stripe::Charge.create(charge_params, charge_headers)
      charge2 = Stripe::Charge.create(charge_params, charge_headers)

      expect(charge1).to eq(charge2)
    end

    context 'different key' do
      let(:different_charge_headers) {{
        idempotency_key: 'thisoneisdifferent'
      }}

      it "returns different charges if different idempotency_keys are used for each charge" do
        charge1 = Stripe::Charge.create(charge_params, charge_headers)
        charge2 = Stripe::Charge.create(charge_params, different_charge_headers)

        expect(charge1).not_to eq(charge2)
      end
    end
  end

end
