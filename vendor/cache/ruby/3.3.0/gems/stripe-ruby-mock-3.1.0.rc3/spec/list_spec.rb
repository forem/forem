require "spec_helper"

describe StripeMock::Data::List do
  let(:stripe_helper) { StripeMock.create_test_helper }

  before :all do
    StripeMock.start
  end

  after :all do
    StripeMock.stop
  end

  it "contains data" do
    obj = double
    obj2 = double
    obj3 = double
    list = StripeMock::Data::List.new([obj, obj2, obj3])

    expect(list.data).to eq([obj, obj2, obj3])
  end

  it "can accept a single object" do
    list = StripeMock::Data::List.new(double)

    expect(list.data).to be_kind_of(Array)
    expect(list.data.size).to eq(1)
  end

  it "infers object type for url" do
    customer = Stripe::Customer.create
    list = StripeMock::Data::List.new([customer])

    expect(list.url).to eq("/v1/customers")
  end

  it "returns in descending order if created available" do
    charge_newer = Stripe::Charge.create(amount: 1, currency: 'usd', source: stripe_helper.generate_card_token, created: 5)
    charge_older = Stripe::Charge.create(amount: 1, currency: 'usd', source: stripe_helper.generate_card_token, created: 4)
    list = StripeMock::Data::List.new([charge_older, charge_newer])
    hash = list.to_h

    expect(hash).to eq(
      object: "list",
      data: [charge_newer, charge_older],
      url: "/v1/charges",
      has_more: false
    )
  end

  it "eventually gets turned into a hash" do
    charge1 = Stripe::Charge.create(amount: 1, currency: 'usd', source: stripe_helper.generate_card_token)
    charge2 = Stripe::Charge.create(amount: 1, currency: 'usd', source: stripe_helper.generate_card_token)
    charge3 = Stripe::Charge.create(amount: 1, currency: 'usd', source: stripe_helper.generate_card_token)
    list = StripeMock::Data::List.new([charge1, charge2, charge3])
    hash = list.to_h

    expect(hash).to eq(
      object: "list",
      data: [charge3, charge2, charge1],
      url: "/v1/charges",
      has_more: false
    )
  end

  it "delegates other methods to hash keys" do
    list = StripeMock::Data::List.new([double, double, double])

    expect(list).to respond_to(:data)
    expect(list.data).to be_kind_of(Array)
    expect(list.object).to eq("list")
    expect(list.has_more).to eq(false)
    expect(list.url).to eq("/v1/doubles")
    expect { list.foobar }.to raise_error(NoMethodError)
  end

  context "with a limit" do
    it "accepts a limit which is reflected in the data returned" do
      list = StripeMock::Data::List.new([double] * 25)

      expect(list.to_h[:data].size).to eq(10)

      list = StripeMock::Data::List.new([double] * 25, limit: 15)

      expect(list.limit).to eq(15)
      expect(list.to_h[:data].size).to eq(15)
    end

    it "defaults to a limit of 10" do
      list = StripeMock::Data::List.new([])

      expect(list.limit).to eq(10)
    end

    it "won't accept a limit of > 100" do
      list = StripeMock::Data::List.new([], limit: 105)

      expect(list.limit).to eq(100)
    end

    it "won't accept a limit of < 1" do
      list = StripeMock::Data::List.new([], limit: 0)

      expect(list.limit).to eq(1)

      list = StripeMock::Data::List.new([], limit: -4)

      expect(list.limit).to eq(1)
    end
  end

  context "active filter" do
    it "accepts an active param which filters out data accordingly" do
      product = Stripe::Product.create(id: "prod_123", name: "My Beautiful Product", type: "service")

      plan_attributes = { product: product.id, interval: "month", currency: "usd", amount: 500 }
      plan_a = Stripe::Plan.create(plan_attributes)
      plan_b = Stripe::Plan.create(**plan_attributes, active: false)

      list = StripeMock::Data::List.new([plan_a, plan_b], active: true)

      expect(list.active).to eq(true)
      expect(list.to_h[:data].count).to eq(1)
    end
  end

  context "pagination" do
    it "has a has_more field when it has more" do
      list = StripeMock::Data::List.new(
        [Stripe::Charge.create(amount: 1, currency: 'usd', source: stripe_helper.generate_card_token)] * 256
      )

      expect(list).to have_more
    end

    it "accepts a starting_after parameter" do
      data = []
      255.times { data << Stripe::Charge.create(amount: 1, currency: 'usd', source: stripe_helper.generate_card_token) }
      new_charge = Stripe::Charge.create(amount: 1, currency: 'usd', source: stripe_helper.generate_card_token)
      data[89] = new_charge
      list = StripeMock::Data::List.new(data, starting_after: new_charge.id)
      hash = list.to_h
      expect(hash[:data].size).to eq(10)
      expect(hash[:data]).to eq(data[79, 10].reverse)
    end

    it "raises an error if starting_after cursor is not found" do
      data = []
      255.times { data << Stripe::Charge.create(amount: 1, currency: 'usd', source: stripe_helper.generate_card_token) }
      list = StripeMock::Data::List.new(data, starting_after: "test_ch_unknown")

      expect { list.to_h }.to raise_error
    end
  end

  context "with data containing records marked 'deleted'" do
    let(:customer_data) { StripeMock.instance.customers.values }
    let(:customers) do
      customer_data.map { |datum| Stripe::Util.convert_to_stripe_object(datum) }
    end

    before do
      StripeMock.instance.customers.clear
      Stripe::Customer.create
      Stripe::Customer.delete(Stripe::Customer.create.id)
    end

    it "does not raise error on initialization" do
      expect { StripeMock::Data::List.new(customer_data) }.to_not raise_error
      expect { StripeMock::Data::List.new(customers) }.to_not raise_error
    end

    it "omits records marked 'deleted'" do
      expect(StripeMock::Data::List.new(customer_data).data.size).to eq(1)
      expect(StripeMock::Data::List.new(customers).data.size).to eq(1)
    end
  end
end
