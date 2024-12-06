require 'spec_helper'

shared_examples 'Transfer API' do

  it "creates a stripe transfer" do
    destination = Stripe::Account.create(type: "custom", email: "#{SecureRandom.uuid}@example.com", id: "acct_12345")
    transfer = Stripe::Transfer.create(amount: 100, currency: "usd", destination: destination.id)

    expect(transfer.id).to match /^test_tr/
    expect(transfer.amount).to eq(100)
    expect(transfer.amount_reversed).to eq(0)
    expect(transfer.balance_transaction).to eq('txn_2dyYXXP90MN26R')
    expect(transfer.created).to eq(1304114826)
    expect(transfer.currency).to eq('usd')
    expect(transfer.description).to eq('Transfer description')
    expect(transfer.destination).to eq('acct_12345')
    expect(transfer.destination_payment).to eq("py_164xRvKbnvuxQXGuVFV2pZo1")
    expect(transfer.livemode).to eq(false)
    expect(transfer.metadata).to eq(Stripe::StripeObject.new)
    expect(transfer.reversals).to eq(Stripe::ListObject.construct_from({
      object: "list",
      data: [],
      total_count: 0,
      has_more: false,
      url: "/v1/transfers/#{transfer.id}/reversals"
    }))
    expect(transfer.reversed).to eq(false)
    expect(transfer.source_transaction).to eq("ch_164xRv2eZvKYlo2Clu1sIJWB")
    expect(transfer.source_type).to eq("card")
    expect(transfer.transfer_group).to eq("group_ch_164xRv2eZvKYlo2Clu1sIJWB")
  end

  describe "listing transfers" do
    let(:destination) { Stripe::Account.create(type: "custom", email: "#{SecureRandom.uuid}@example.com", business_name: "MyCo") }

    before do
      3.times do
        Stripe::Transfer.create(amount: "100", currency: "usd", destination: destination.id)
      end
    end

    it "without params retrieves all tripe transfers" do
      expect(Stripe::Transfer.list.count).to eq(3)
    end

    it "accepts a limit param" do
      expect(Stripe::Transfer.list(limit: 2).count).to eq(2)
    end

    it "filters the search to a specific destination" do
      d2 = Stripe::Account.create(type: "custom", email: "#{SecureRandom.uuid}@example.com", business_name: "MyCo")
      Stripe::Transfer.create(amount: "100", currency: "usd", destination: d2.id)

      expect(Stripe::Transfer.list(destination: d2.id).count).to eq(1)
    end

    it "disallows unknown parameters" do
      expect { Stripe::Transfer.list(recipient: "foo") }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.param).to eq("recipient")
        expect(e.message).to eq("Received unknown parameter: recipient")
        expect(e.http_status).to eq(400)
      }
    end
  end


  it "retrieves a stripe transfer" do
    original = Stripe::Transfer.create(amount: "100", currency: "usd")
    transfer = Stripe::Transfer.retrieve(original.id)

    expect(transfer.id).to eq(original.id)
    expect(transfer.object).to eq(original.object)
    expect(transfer.amount).to eq(original.amount)
    expect(transfer.amount_reversed).to eq(original.amount_reversed)
    expect(transfer.balance_transaction).to eq(original.balance_transaction)
    expect(transfer.created).to eq(original.created)
    expect(transfer.currency).to eq(original.currency)
    expect(transfer.description).to eq(original.description)
    expect(transfer.destination).to eq(original.destination)
    expect(transfer.destination_payment).to eq(original.destination_payment)
    expect(transfer.livemode).to eq(original.livemode)
    expect(transfer.metadata).to eq(original.metadata)
    expect(transfer.reversals).to eq(original.reversals)
    expect(transfer.reversed).to eq(original.reversed)
    expect(transfer.source_transaction).to eq(original.source_transaction)
    expect(transfer.source_type).to eq(original.source_type)
    expect(transfer.transfer_group).to eq(original.transfer_group)
  end

  it "cancels a stripe transfer" do
    original = Stripe::Transfer.create(amount:  "100", currency: "usd")
    res, api_key = Stripe::StripeClient.active_client.execute_request(:post, "/v1/transfers/#{original.id}/cancel", api_key: 'api_key')

    expect(res.data[:status]).to eq("canceled")
  end

  it "cannot retrieve a transfer that doesn't exist" do
    expect { Stripe::Transfer.retrieve('nope') }.to raise_error {|e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('transfer')
      expect(e.http_status).to eq(404)
    }
  end

  it "when amount is not integer", live: true do
    dest = Stripe::Account.create(type: "custom", email: "#{SecureRandom.uuid}@example.com", requested_capabilities: ['card_payments', 'platform_payments'])
    expect { Stripe::Transfer.create(amount: '400.2',
                                     currency: 'usd',
                                     destination: dest.id,
                                     description: 'Transfer for test@example.com') }.to raise_error { |e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('amount')
      expect(e.http_status).to eq(400)
    }
  end

  it "when amount is negative", live: true do
    dest = Stripe::Account.create(type: "custom", email: "#{SecureRandom.uuid}@example.com", requested_capabilities: ['card_payments', 'platform_payments'])
    expect { Stripe::Transfer.create(amount: '-400',
                                     currency: 'usd',
                                     destination: dest.id,
                                     description: 'Transfer for test@example.com') }.to raise_error { |e|
      expect(e).to be_a Stripe::InvalidRequestError
      expect(e.param).to eq('amount')
      expect(e.message).to match(/^Invalid.*integer/)
      expect(e.http_status).to eq(400)
    }
  end
end
