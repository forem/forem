require 'spec_helper'

shared_examples 'Plan API' do
  let(:product) { stripe_helper.create_product }
  let(:product_id) { product.id }

  let(:plan_attributes) { {
    :id => "plan_abc123",
    :product => product_id,
    :nickname => "My Mock Plan",
    :amount => 9900,
    :currency => "usd",
    :interval => "month"
  } }
  let(:plan) { Stripe::Plan.create(plan_attributes) }

  let(:plan_attributes_without_id){ plan_attributes.merge(id: nil) }
  let(:plan_without_id){ Stripe::Plan.create(plan_attributes_without_id) }

  let(:plan_attributes_with_trial) { plan_attributes.merge(id: "prod_TRIAL", :trial_period_days => 30) }
  let(:plan_with_trial) { Stripe::Plan.create(plan_attributes_with_trial) }

  let(:metadata) { {:description => "desc text", :info => "info text"} }
  let(:plan_attributes_with_metadata) { plan_attributes.merge(id: "prod_META", metadata: metadata) }
  let(:plan_with_metadata) { Stripe::Plan.create(plan_attributes_with_metadata) }

  before(:each) do
    product
  end

  it "creates a stripe plan" do
    expect(plan.id).to eq('plan_abc123')
    expect(plan.nickname).to eq('My Mock Plan')
    expect(plan.amount).to eq(9900)

    expect(plan.currency).to eq('usd')
    expect(plan.interval).to eq("month")

    expect(plan_with_metadata.metadata.description).to eq('desc text')
    expect(plan_with_metadata.metadata.info).to eq('info text')

    expect(plan_with_trial.trial_period_days).to eq(30)
  end

  it "creates a stripe plan without specifying ID" do
    expect(plan_attributes_without_id[:id]).to be_nil
    expect(plan_without_id.id).to match(/^test_plan_1/)
  end

  it "stores a created stripe plan in memory" do
    plan
    plan2 = Stripe::Plan.create(plan_attributes.merge(id: "plan_def456", amount: 299))

    data = test_data_source(:plans)
    expect(data[plan.id]).to_not be_nil
    expect(data[plan.id][:amount]).to eq(9900)
    expect(data[plan2.id]).to_not be_nil
    expect(data[plan2.id][:amount]).to eq(299)
  end

  it "retrieves a stripe plan" do
    original = stripe_helper.create_plan(product: product_id, amount: 1331, id: 'plan_943843')
    plan = Stripe::Plan.retrieve(original.id)

    expect(plan.id).to eq(original.id)
    expect(plan.amount).to eq(original.amount)
  end

  it "updates a stripe plan" do
    stripe_helper.create_plan(id: 'super_member', product: product_id, amount: 111)

    plan = Stripe::Plan.retrieve('super_member')
    expect(plan.amount).to eq(111)

    plan.amount = 789
    plan.save
    plan = Stripe::Plan.retrieve('super_member')
    expect(plan.amount).to eq(789)
  end

  it "cannot retrieve a stripe plan that doesn't exist" do
    expect { Stripe::Plan.retrieve('nope') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('plan')
      expect(e.http_status).to eq(404)
    }
  end

  it "deletes a stripe plan" do
    stripe_helper.create_plan(id: 'super_member', product: product_id, amount: 111)

    plan = Stripe::Plan.retrieve('super_member')
    expect(plan).to_not be_nil

    plan.delete

    expect { Stripe::Plan.retrieve('super_member') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('plan')
      expect(e.http_status).to eq(404)
    }
  end

  it "retrieves all plans" do
    stripe_helper.create_plan(id: 'Plan One', product: product_id, amount: 54321)
    stripe_helper.create_plan(id: 'Plan Two', product: product_id, amount: 98765)

    all = Stripe::Plan.list
    expect(all.count).to eq(2)
    expect(all.map &:id).to include('Plan One', 'Plan Two')
    expect(all.map &:amount).to include(54321, 98765)
  end

  it 'retrieves plans with limit' do
    101.times do | i|
      stripe_helper.create_plan(id: "Plan #{i}", product: product_id, amount: 11)
    end
    all = Stripe::Plan.list(limit: 100)

    expect(all.count).to eq(100)
  end

  describe "Validations", :live => true do
    include_context "stripe validator"
    let(:params) { stripe_helper.create_plan_params(product: product_id) }
    let(:subject) { Stripe::Plan.create(params) }

    describe "Associations" do
      let(:not_found_product_id){ "prod_NONEXIST" }
      let(:not_found_message) { stripe_validator.not_found_message(Stripe::Product, not_found_product_id) }
      let(:params) { stripe_helper.create_plan_params(product: not_found_product_id) }
      let(:products) { stripe_helper.list_products(100).data }

      it "validates associated product" do
        expect(products.map(&:id)).to_not include(not_found_product_id)
        expect { subject }.to raise_error(Stripe::InvalidRequestError, not_found_message)
      end
    end

    describe "Presence" do
      after do
        params.delete(@name)
        message =
          if @name == :amount
            "Plans require an `#{@name}` parameter to be set."
          else
            "Missing required param: #{@name}."
          end
        expect { subject }.to raise_error(Stripe::InvalidRequestError, message)
      end

      it("validates presence of interval") { @name = :interval }
      it("validates presence of currency") { @name = :currency }
      it("validates presence of product") { @name = :product }
      it("validates presence of amount") { @name = :amount }
    end

    describe "Inclusion" do
      let(:invalid_interval) { "OOPS" }
      let(:invalid_interval_message) { stripe_validator.invalid_plan_interval_message }
      let(:invalid_interval_params) { params.merge({interval: invalid_interval}) }
      let(:plan_with_invalid_interval) { Stripe::Plan.create(invalid_interval_params) }

      before(:each) do
        product
      end

      it "validates inclusion of interval" do
        expect { plan_with_invalid_interval }.to raise_error(Stripe::InvalidRequestError, invalid_interval_message)
      end

      let(:invalid_currency) { "OOPS" }
      let(:invalid_currency_message) { stripe_validator.invalid_currency_message(invalid_currency) }
      let(:invalid_currency_params) { params.merge({currency: invalid_currency}) }
      let(:plan_with_invalid_currency) { Stripe::Plan.create(invalid_currency_params) }

      it "validates inclusion of currency" do
        expect { plan_with_invalid_currency }.to raise_error(Stripe::InvalidRequestError, invalid_currency_message)
      end
    end

    describe "Numericality" do
      let(:invalid_integer) { 99.99 }
      let(:invalid_integer_message) { stripe_validator.invalid_integer_message(invalid_integer)}

      it 'validates amount is an integer' do
        expect {
          Stripe::Plan.create( plan_attributes.merge({amount: invalid_integer}) )
        }.to raise_error(Stripe::InvalidRequestError, invalid_integer_message)
      end
    end

    describe "Uniqueness" do
      let(:already_exists_message) { stripe_validator.already_exists_message(Stripe::Plan) }

      it "validates for uniqueness" do
        stripe_helper.delete_plan(params[:id])

        Stripe::Plan.create(params)
        expect {
          Stripe::Plan.create(params)
        }.to raise_error(Stripe::InvalidRequestError, already_exists_message)
      end
    end

  end

  describe "Mock Data" do
    let(:mock_object) { StripeMock::Data.mock_plan }
    let(:known_attributes) { [
      :id,
      :object,
      :active,
      :aggregate_usage,
      :amount,
      :billing_scheme,
      :created,
      :currency,
      :interval,
      :interval_count,
      :livemode,
      :metadata,
      :nickname,
      :product,
      :tiers,
      :tiers_mode,
      :transform_usage,
      :trial_period_days,
      :usage_type
    ] }

    it "includes all retreived attributes" do
      expect(mock_object.keys).to eql(known_attributes)
    end
  end

end
