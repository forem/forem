require 'spec_helper'

shared_examples 'Customer API' do
  let(:product_params) { {id: "prod_CCC", name: "My Product", type: "service"} }
  let(:product) { stripe_helper.create_product(product_params) }

  def gen_card_tk
    stripe_helper.generate_card_token
  end

  it "creates a stripe customer with a default card" do
    customer = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      source: gen_card_tk,
      description: "a description"
    })
    expect(customer.id).to match(/^test_cus/)
    expect(customer.email).to eq('johnny@appleseed.com')
    expect(customer.description).to eq('a description')
    expect(customer.preferred_locales).to eq([])

    expect(customer.sources.count).to eq(1)
    expect(customer.sources.data.length).to eq(1)
    expect(customer.default_source).to_not be_nil
    expect(customer.default_source).to eq customer.sources.data.first.id

    expect { customer.source }.to raise_error
  end

  it "creates a stripe customer with a default payment method" do
    customer = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      invoice_settings: {
        default_payment_method: "pm_1ExEuFL2DI6wht39WNJgbybl"
      },
      description: "a description"
    })
    expect(customer.invoice_settings.default_payment_method).to eq("pm_1ExEuFL2DI6wht39WNJgbybl")
  end

  it "creates a stripe customer with multiple cards and updates the default card" do
    card_a   = gen_card_tk
    card_b   = gen_card_tk
    customer = Stripe::Customer.create({
      email: 'johnny.multiple@appleseed.com',
      source: card_a,
      description: "a description"
    })

    original_card = customer.sources.data.first.id

    customer.sources.create(source: card_b)
    retrieved_customer = Stripe::Customer.retrieve(customer.id)

    expect(retrieved_customer.sources.data.length).to eq(2)
    retrieved_customer.default_source = retrieved_customer.sources.data.last.id
    retrieved_customer.save
    expect(Stripe::Customer.retrieve(customer.id).default_source).to eq(retrieved_customer.sources.data.last.id)
    expect(Stripe::Customer.retrieve(customer.id).default_source).to_not eq(original_card)
  end

  it "creates a stripe customer without a card" do
    customer = Stripe::Customer.create({
      email: 'cardless@appleseed.com',
      description: "no card"
    })
    expect(customer.id).to match(/^test_cus/)
    expect(customer.email).to eq('cardless@appleseed.com')
    expect(customer.description).to eq('no card')

    expect(customer.sources.count).to eq(0)
    expect(customer.sources.data.length).to eq(0)
    expect(customer.default_source).to be_nil
  end

  it 'creates a stripe customer with a dictionary of card values', live: true do
    customer = Stripe::Customer.create(source: {
                                           object: 'card',
                                           number: '4242424242424242',
                                           exp_month: 12,
                                           exp_year: 2024,
                                           cvc: 123
                                       },
                                       email: 'blah@blah.com')

    expect(customer).to be_a Stripe::Customer
    expect(customer.id).to match(/cus_/)
    expect(customer.email).to eq 'blah@blah.com'
    expect(customer.sources.data.first.object).to eq 'card'
    expect(customer.sources.data.first.last4).to eq '4242'
    expect(customer.sources.data.first.exp_month).to eq 12
    expect(customer.sources.data.first.exp_year).to eq 2024
  end

  it 'creates a customer with name' do
    customer = Stripe::Customer.create(
      source: gen_card_tk,
      name: 'John Appleseed'
    )
    expect(customer.id).to match(/^test_cus/)
    expect(customer.name).to eq('John Appleseed')
  end

  it 'creates a customer with a plan' do
    plan = stripe_helper.create_plan(id: 'silver', product: product.id)
    customer = Stripe::Customer.create(id: 'test_cus_plan', source: gen_card_tk, :plan => 'silver')

    customer = Stripe::Customer.retrieve('test_cus_plan')
    expect(customer.subscriptions.count).to eq(1)
    expect(customer.subscriptions.data.length).to eq(1)

    expect(customer.subscriptions).to_not be_nil
    expect(customer.subscriptions.first.plan.id).to eq('silver')
    expect(customer.subscriptions.first.customer).to eq(customer.id)
  end

  it 'creates a customer with a plan (string/symbol agnostic)' do
    stripe_helper.create_plan(id: 'silver', product: product.id)

    Stripe::Customer.create(id: 'cust_SLV1', source: gen_card_tk, :plan => 'silver')
    customer = Stripe::Customer.retrieve('cust_SLV1')
    expect(customer.subscriptions.count).to eq(1)
    expect(customer.subscriptions.data.length).to eq(1)
    expect(customer.subscriptions).to_not be_nil
    expect(customer.subscriptions.first.plan.id).to eq('silver')
    expect(customer.subscriptions.first.customer).to eq(customer.id)

    Stripe::Customer.create(id: 'cust_SLV2', source: gen_card_tk, :plan => :silver)
    customer = Stripe::Customer.retrieve('cust_SLV2')
    expect(customer.subscriptions.count).to eq(1)
    expect(customer.subscriptions.data.length).to eq(1)
    expect(customer.subscriptions).to_not be_nil
    expect(customer.subscriptions.first.plan.id).to eq('silver')
    expect(customer.subscriptions.first.customer).to eq(customer.id)
  end

  context "create customer" do
    it "with a trial when trial_end is set" do
      plan = stripe_helper.create_plan(id: 'no_trial', product: product.id, amount: 999)
      trial_end = Time.now.utc.to_i + 3600
      customer = Stripe::Customer.create(id: 'test_cus_trial_end', source: gen_card_tk, plan: 'no_trial', trial_end: trial_end)

      customer = Stripe::Customer.retrieve('test_cus_trial_end')
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions).to_not be_nil
      expect(customer.subscriptions.first.plan.id).to eq('no_trial')
      expect(customer.subscriptions.first.status).to eq('trialing')
      expect(customer.subscriptions.first.current_period_end).to eq(trial_end)
      expect(customer.subscriptions.first.trial_end).to eq(trial_end)
    end

    it 'overrides trial period length when trial_end is set' do
      plan = stripe_helper.create_plan(id: 'silver', product: product.id, amount: 999, trial_period_days: 14)
      trial_end = Time.now.utc.to_i + 3600
      customer = Stripe::Customer.create(id: 'test_cus_trial_end', source: gen_card_tk, plan: 'silver', trial_end: trial_end)

      customer = Stripe::Customer.retrieve('test_cus_trial_end')
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions).to_not be_nil
      expect(customer.subscriptions.first.plan.id).to eq('silver')
      expect(customer.subscriptions.first.current_period_end).to eq(trial_end)
      expect(customer.subscriptions.first.trial_end).to eq(trial_end)
    end

    it 'creates a customer when trial_end is set and no source', live: true do
      plan = stripe_helper.create_plan(id: 'silver', product: product.id, amount: 999)
      trial_end = Time.now.utc.to_i + 3600
      customer = Stripe::Customer.create(plan: 'silver', trial_end: trial_end)
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions).to_not be_nil
      expect(customer.subscriptions.first.plan.id).to eq('silver')
      expect(customer.subscriptions.first.current_period_end).to eq(trial_end)
      expect(customer.subscriptions.first.trial_end).to eq(trial_end)
    end

    it "returns no trial when trial_end is set to 'now'" do
      plan = stripe_helper.create_plan(id: 'silver', product: product.id, amount: 999, trial_period_days: 14)
      customer = Stripe::Customer.create(id: 'test_cus_trial_end', source: gen_card_tk, plan: 'silver', trial_end: "now")

      customer = Stripe::Customer.retrieve('test_cus_trial_end')
      expect(customer.subscriptions.count).to eq(1)
      expect(customer.subscriptions.data.length).to eq(1)

      expect(customer.subscriptions).to_not be_nil
      expect(customer.subscriptions.first.plan.id).to eq('silver')
      expect(customer.subscriptions.first.status).to eq('active')
      expect(customer.subscriptions.first.trial_start).to be_nil
      expect(customer.subscriptions.first.trial_end).to be_nil
    end

    it 'returns an error if trial_end is set to a past time' do
      plan = stripe_helper.create_plan(id: 'silver', product: product.id, amount: 999)
      expect {
        Stripe::Customer.create(id: 'test_cus_trial_end', source: gen_card_tk, plan: 'silver', trial_end: Time.now.utc.to_i - 3600)
      }.to raise_error {|e|
        expect(e).to be_a(Stripe::InvalidRequestError)
        expect(e.message).to eq('Invalid timestamp: must be an integer Unix timestamp in the future')
      }
    end

    it 'returns an error if trial_end is set without a plan' do
      expect {
        Stripe::Customer.create(id: 'test_cus_trial_end', source: gen_card_tk, trial_end: "now")
      }.to raise_error {|e|
        expect(e).to be_a(Stripe::InvalidRequestError)
        expect(e.message).to eq('Received unknown parameter: trial_end')
      }
    end

  end

  it 'cannot create a customer with a plan that does not exist' do
    expect {
      Stripe::Customer.create(id: 'test_cus_no_plan', source: gen_card_tk, :plan => 'non-existant')
    }.to raise_error {|e|
      expect(e).to be_a(Stripe::InvalidRequestError)
      expect(e.message).to eq('No such plan: non-existant')
    }
  end

  it 'cannot create a customer with an existing plan, but no card token' do
    plan = stripe_helper.create_plan(id: 'p', product: product.id)
    expect {
      Stripe::Customer.create(id: 'test_cus_no_plan', :plan => 'p')
    }.to raise_error {|e|
      expect(e).to be_a(Stripe::InvalidRequestError)
      expect(e.message).to eq('You must supply a valid card')
    }
  end

  it 'creates a customer with a coupon discount' do
    coupon = Stripe::Coupon.create(id: '10PERCENT', duration: 'once')

    Stripe::Customer.create(id: 'test_cus_coupon', coupon: '10PERCENT')

    customer = Stripe::Customer.retrieve('test_cus_coupon')
    expect(customer.discount).to_not be_nil
    expect(customer.discount.coupon).to_not be_nil
    expect(customer.discount.customer).to eq customer.id
    expect(customer.discount.start).to be_within(1).of Time.now.to_i
  end

  describe 'repeating coupon with duration limit', live: true do
    let!(:coupon) { stripe_helper.create_coupon(id: '10OFF', amount_off: 1000, currency: 'usd', duration: 'repeating', duration_in_months: 12) }
    let!(:customer) { Stripe::Customer.create(coupon: coupon.id) }

    it 'creates the discount with the end date', live: true do
      discount = Stripe::Customer.retrieve(customer.id).discount
      expect(discount).to_not be_nil
      expect(discount.coupon).to_not be_nil
      expect(discount.end).to be_within(10).of (DateTime.now >> 12).to_time.to_i
    end

    after { Stripe::Coupon.retrieve(coupon.id).delete }
    after { Stripe::Customer.retrieve(customer.id).delete }
  end

  it 'cannot create a customer with a coupon that does not exist' do
    expect{
      Stripe::Customer.create(id: 'test_cus_no_coupon', coupon: '5OFF')
    }.to raise_error {|e|
      expect(e).to be_a(Stripe::InvalidRequestError)
      expect(e.message).to eq('No such coupon: 5OFF')
    }
  end

  context 'with coupon on customer' do
    before do
      Stripe::Coupon.create(id: '10PERCENT', duration: 'once')
      Stripe::Customer.create(id: 'test_cus_coupon', coupon: '10PERCENT')
    end

    it 'remove the coupon from customer' do
      customer = Stripe::Customer.retrieve('test_cus_coupon')
      expect(customer.discount).to_not be_nil
      expect(customer.discount.coupon).to_not be_nil
      expect(customer.discount.customer).to eq customer.id
      expect(customer.discount.start).to be_within(1).of Time.now.to_i

      Stripe::Customer.update('test_cus_coupon', coupon: '')
      customer = Stripe::Customer.retrieve('test_cus_coupon')
      expect(customer.discount).to be_nil
    end
  end

  it "stores a created stripe customer in memory" do
    customer = Stripe::Customer.create(email: 'johnny@appleseed.com')
    customer2 = Stripe::Customer.create(email: 'bob@bobbers.com')
    data = test_data_source(:customers)
    list = data[data.keys.first]

    customer_hash = list[customer.id.to_sym] || list[customer.id]
    expect(customer_hash).to_not be_nil
    expect(customer_hash[:email]).to eq('johnny@appleseed.com')

    customer2_hash = list[customer2.id.to_sym] || list[customer2.id]
    expect(customer2_hash).to_not be_nil
    expect(customer2_hash[:email]).to eq('bob@bobbers.com')
  end

  it "retrieves a stripe customer" do
    original = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      source: gen_card_tk
    })
    customer = Stripe::Customer.retrieve(original.id)

    expect(customer.id).to eq(original.id)
    expect(customer.email).to eq(original.email)
    expect(customer.name).to eq(nil)
    expect(customer.default_source).to eq(original.default_source)
    expect(customer.default_source).not_to be_a(Stripe::Card)
    expect(customer.subscriptions.count).to eq(0)
    expect(customer.subscriptions.data).to be_empty
  end

  it "can expand default_source" do
    original = Stripe::Customer.create({
      email: 'johnny@appleseed.com',
      source: gen_card_tk
    })
    customer = Stripe::Customer.retrieve(
      id: original.id,
      expand: ['default_source']
    )
    expect(customer.default_source).to be_a(Stripe::Card)
  end

  it "cannot retrieve a customer that doesn't exist" do
    expect { Stripe::Customer.retrieve('nope') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('customer')
      expect(e.http_status).to eq(404)
    }
  end

  it "retrieves all customers" do
    Stripe::Customer.create({ email: 'one@one.com' })
    Stripe::Customer.create({ email: 'two@two.com' })

    all = Stripe::Customer.list
    expect(all.count).to eq(2)
    expect(all.data.map &:email).to include('one@one.com', 'two@two.com')
  end

  it "updates a stripe customer" do
    original = Stripe::Customer.create(id: 'test_customer_update')
    email = original.email

    coupon = Stripe::Coupon.create(id: "10PERCENT", duration: 'once')
    original.description       = 'new desc'
    original.preferred_locales = %w(fr en)
    original.coupon            = coupon.id
    original.save

    expect(original.email).to eq(email)
    expect(original.description).to eq('new desc')
    expect(original.discount.coupon).to be_a Stripe::Coupon

    customer = Stripe::Customer.retrieve("test_customer_update")
    expect(customer.email).to eq(original.email)
    expect(customer.description).to eq('new desc')
    expect(customer.preferred_locales).to eq(%w(fr en))
    expect(customer.discount.coupon).to be_a Stripe::Coupon
  end

  it "preserves stripe customer metadata" do
    metadata = {user_id: "38"}
    customer = Stripe::Customer.create(metadata: metadata)
    expect(customer.metadata.to_h).to eq(metadata)

    updated = Stripe::Customer.update(customer.id, metadata: {fruit: "apples"})
    expect(updated.metadata.to_h).to eq(metadata.merge(fruit: "apples"))
  end

  it "retrieves the customer's default source after it was updated" do
    customer = Stripe::Customer.create()
    customer.source = gen_card_tk
    customer.save
    card = customer.sources.retrieve(customer.default_source)

    expect(customer.sources).to be_a(Stripe::ListObject)
    expect(card).to be_a(Stripe::Card)
  end

  it "updates a stripe customer's card from a token" do
    original = Stripe::Customer.create( source: gen_card_tk)
    card = original.sources.data.first
    expect(original.default_source).to eq(card.id)
    expect(original.sources.data.count).to eq(1)

    original.source = gen_card_tk
    original.save

    new_card = original.sources.data.last
    expect(original.sources.data.count).to eq(1)
    expect(original.default_source).to_not eq(card.id)

    expect(new_card.id).to_not eq(card.id)
  end

  it "updates a stripe customer's card from a hash" do
    original = Stripe::Customer.create( source: gen_card_tk)
    card = original.sources.data.first
    expect(original.default_source).to eq(card.id)
    expect(original.sources.data.count).to eq(1)

    original.source = {
      object: 'card',
      number: '4012888888881881',
      exp_year: 2018,
      exp_month: 12,
      cvc: 666
    }

    original.save

    new_card = original.sources.data.last
    expect(original.sources.data.count).to eq(1)
    expect(original.default_source).to_not eq(card.id)
  end

  it "still has sources after save when sources unchanged" do
    original = Stripe::Customer.create(source: gen_card_tk)
    card = original.sources.data.first
    card_id = card.id
    expect(original.sources.total_count).to eq(1)

    original.save

    expect(original.sources.data.first.id).to eq(card_id)
    expect(original.sources.total_count).to eq(1)
  end

  it "still has subscriptions after save when subscriptions unchanged" do
    plan = stripe_helper.create_plan(id: 'silver', product: product.id)
    original = Stripe::Customer.create(source: gen_card_tk, plan: 'silver')
    subscription = original.subscriptions.data.first
    subscription_id = subscription.id
    expect(original.subscriptions.total_count).to eq(1)

    original.save

    expect(original.subscriptions.data.first.id).to eq(subscription_id)
    expect(original.subscriptions.total_count).to eq(1)
  end

  it "should add a customer to a subscription" do
    plan     = stripe_helper.create_plan(id: 'silver', product: product.id)
    customer = Stripe::Customer.create(source: gen_card_tk)
    customer.subscriptions.create(plan: plan.id)

    expect(Stripe::Customer.retrieve(customer.id).subscriptions.total_count).to eq(1)
  end

  it "deletes a customer" do
    customer = Stripe::Customer.create(id: 'test_customer_sub')
    customer = customer.delete
    expect(customer.deleted).to eq(true)
  end

  it "deletes a stripe customer discount" do
    original = Stripe::Customer.create(id: 'test_customer_update')

    coupon = Stripe::Coupon.create(id: "10PERCENT", duration: 'once')
    original.coupon = coupon.id
    original.save

    expect(original.discount.coupon).to be_a Stripe::Coupon

    original.delete_discount

    customer = Stripe::Customer.retrieve("test_customer_update")
    expect(customer.discount).to be nil
  end
end
