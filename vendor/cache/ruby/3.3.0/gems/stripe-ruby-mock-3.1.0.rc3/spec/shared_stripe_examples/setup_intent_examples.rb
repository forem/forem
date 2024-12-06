require 'spec_helper'

shared_examples 'SetupIntent API' do

  it "creates a stripe setup_intent" do
    setup_intent = Stripe::SetupIntent.create()

    expect(setup_intent.id).to match(/^test_si/)
    expect(setup_intent.metadata.to_hash).to eq({})
    expect(setup_intent.status).to eq('requires_payment_method')
  end

  describe "listing setup_intent" do
    before do
      3.times do
        Stripe::SetupIntent.create()
      end
    end

    it "without params retrieves all stripe setup_intent" do
      expect(Stripe::SetupIntent.list.count).to eq(3)
    end

    it "accepts a limit param" do
      expect(Stripe::SetupIntent.list(limit: 2).count).to eq(2)
    end
  end

  it "retrieves a stripe setup_intent" do
    original = Stripe::SetupIntent.create()
    setup_intent = Stripe::SetupIntent.retrieve(original.id)

    expect(setup_intent.id).to eq(original.id)
    expect(setup_intent.metadata.to_hash).to eq(original.metadata.to_hash)
  end

  it "cannot retrieve a setup_intent that doesn't exist" do
    expect { Stripe::SetupIntent.retrieve('nope') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('setup_intent')
      expect(e.http_status).to eq(404)
    }
  end

  it "confirms a stripe setup_intent" do
    setup_intent = Stripe::SetupIntent.create()
    confirmed_setup_intent = setup_intent.confirm()
    expect(confirmed_setup_intent.status).to eq("succeeded")
  end

  it "cancels a stripe setup_intent" do
    setup_intent = Stripe::SetupIntent.create()
    confirmed_setup_intent = setup_intent.cancel()
    expect(confirmed_setup_intent.status).to eq("canceled")
  end

  it "updates a stripe setup_intent" do
    original = Stripe::SetupIntent.create()
    setup_intent = Stripe::SetupIntent.retrieve(original.id)

    setup_intent.metadata[:foo] = :bar
    setup_intent.save

    updated = Stripe::SetupIntent.retrieve(original.id)

    expect(updated.metadata[:foo]).to eq(:bar)
  end
end
