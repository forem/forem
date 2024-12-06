require 'spec_helper'

shared_examples 'Payout API' do

  it "creates a stripe payout" do
    payout = Stripe::Payout.create(amount:  "100", currency: "usd")

    expect(payout.id).to match(/^test_po/)
    expect(payout.amount).to eq('100')
    expect(payout.currency).to eq('usd')
    expect(payout.metadata.to_hash).to eq({})
  end

  describe "listing payouts" do
    before do
      3.times do
        Stripe::Payout.create(amount: "100", currency: "usd")
      end
    end

    it "without params retrieves all tripe payouts" do
      expect(Stripe::Payout.list.count).to eq(3)
    end

    it "accepts a limit param" do
      expect(Stripe::Payout.list(limit: 2).count).to eq(2)
    end
  end

  it "retrieves a stripe payout" do
    original = Stripe::Payout.create(amount:  "100", currency: "usd")
    payout = Stripe::Payout.retrieve(original.id)

    expect(payout.id).to eq(original.id)
    expect(payout.amount).to eq(original.amount)
    expect(payout.currency).to eq(original.currency)
    expect(payout.metadata.to_hash).to eq(original.metadata.to_hash)
  end

  it "cannot retrieve a payout that doesn't exist" do
    expect { Stripe::Payout.retrieve('nope') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('payout')
      expect(e.http_status).to eq(404)
    }
  end

  it 'when amount is not integer', live: true do
    expect { Stripe::Payout.create(amount: '400.2',
                                       currency: 'usd',
                                       description: 'Payout for test@example.com') }.to raise_error { |e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('amount')
      expect(e.http_status).to eq(400)
    }
  end

  it 'when amount is negative', live: true do
    expect { Stripe::Payout.create(amount: '-400',
                                     currency: 'usd',
                                     description: 'Payout for test@example.com') }.to raise_error { |e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('amount')
      expect(e.message).to match(/^Invalid.*integer/)
      expect(e.http_status).to eq(400)
    }
  end
end
