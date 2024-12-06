require 'spec_helper'

shared_examples 'Refund API' do

  describe 'standard API' do
    it "refunds a stripe charge item" do
      charge = Stripe::Charge.create(
        amount: 999,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        description: 'card charge'
      )

      Stripe::Refund.create(
        charge: charge.id
      )

      charge = Stripe::Charge.retrieve(charge.id)

      expect(charge.refunded).to eq(true)
      expect(charge.refunds.data.first.amount).to eq(999)
      expect(charge.amount_refunded).to eq(999)
    end

    it "creates a stripe refund with a status" do
      charge = Stripe::Charge.create(
        amount: 999,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        description: 'card charge'
      )

      Stripe::Refund.create(charge: charge.id)

      charge = Stripe::Charge.retrieve(charge.id)

      expect(charge.refunds.data.count).to eq 1
      expect(charge.refunds.data.first.status).to eq("succeeded")
    end

    it "creates a stripe refund with a different balance transaction than the charge" do
      charge = Stripe::Charge.create(
        amount: 999,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        description: 'card charge'
      )

      Stripe::Refund.create(
        charge: charge.id
      )

      charge = Stripe::Charge.retrieve(charge.id)

      expect(charge.balance_transaction).not_to eq(charge.refunds.data.first.balance_transaction)
    end

    it "creates a refund off a charge", :live => true do
      original = Stripe::Charge.create(
        amount: 555,
        currency: 'USD',
        source: stripe_helper.generate_card_token
      )

      charge = Stripe::Charge.retrieve(original.id)

      refund = Stripe::Refund.create(
        charge: charge.id,
        amount: 555
      )

      expect(refund.amount).to eq 555
      expect(refund.charge).to eq charge.id
    end

    it "handles multiple refunds", :live => true do
      original = Stripe::Charge.create(
        amount: 1100,
        currency: 'USD',
        source: stripe_helper.generate_card_token
      )

      charge = Stripe::Charge.retrieve(original.id)

      refund_1 = Stripe::Refund.create(
        charge: charge.id,
        amount: 300
      )
      expect(refund_1.amount).to eq 300
      expect(refund_1.charge).to eq charge.id

      refund_2 = Stripe::Refund.create(
        charge: charge.id,
        amount: 400
      )
      expect(refund_2.amount).to eq 400
      expect(refund_2.charge).to eq charge.id

      expect(charge.refunds.count).to eq 0
      expect(charge.refunds.total_count).to eq 0
      expect(charge.amount_refunded).to eq 0

      charge = Stripe::Charge.retrieve(original.id)
      expect(charge.refunds.count).to eq 2
      expect(charge.refunds.total_count).to eq 2
      expect(charge.amount_refunded).to eq 700
    end

    it 'returns Stripe::Refund object', live: true do
      charge = Stripe::Charge.create(
        amount: 999,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        description: 'card charge'
      )
      refund = Stripe::Refund.create(
        charge: charge.id,
        amount: 500
      )

      expect(refund).to be_a(Stripe::Refund)
      expect(refund.amount).to eq(500)
    end

    it 'refunds entire charge if amount is not set', live: true do
      charge = Stripe::Charge.create(
        amount: 999,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        description: 'card charge'
      )
      refund = Stripe::Refund.create(charge: charge.id)

      expect(refund.amount).to eq(charge.amount)
    end

    it "stores a created stripe refund in memory" do
      charge_1 = Stripe::Charge.create({
        amount: 333,
        currency: 'USD',
        source: stripe_helper.generate_card_token
      })
      refund_1 = Stripe::Refund.create(
        charge: charge_1.id,
      )
      charge_2 = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        source: stripe_helper.generate_card_token
      })
      refund_2 = Stripe::Refund.create(
        charge: charge_2.id,
      )

      data = test_data_source(:refunds)
      expect(data[refund_1.id]).to_not be_nil
      expect(data[refund_1.id][:amount]).to eq(333)

      expect(data[refund_2.id]).to_not be_nil
      expect(data[refund_2.id][:amount]).to eq(777)
    end

    it "creates a balance transaction" do
      charge = Stripe::Charge.create({
        amount: 300,
        currency: 'USD',
        source: stripe_helper.generate_card_token
      })
      refund = Stripe::Refund.create(
        charge: charge.id,
      )
      bal_trans = Stripe::BalanceTransaction.retrieve(refund.balance_transaction)
      expect(bal_trans.amount).to eq(charge.amount * -1)
      expect(bal_trans.fee).to eq(-39)
      expect(bal_trans.source).to eq(refund.id)
    end

    it "can expand balance transaction" do
      charge = Stripe::Charge.create({
        amount: 300,
        currency: 'USD',
        source: stripe_helper.generate_card_token
      })
      refund = Stripe::Refund.create(
        charge: charge.id,
        expand: ['balance_transaction']
      )
      expect(refund.balance_transaction).to be_a(Stripe::BalanceTransaction)
    end

    it "retrieves a stripe refund" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        source: stripe_helper.generate_card_token
      })
      original = Stripe::Refund.create(
        charge: charge.id
      )
      refund = Stripe::Refund.retrieve(original.id)

      expect(refund.id).to eq(original.id)
      expect(refund.amount).to eq(original.amount)
    end

    it "cannot retrieve a refund that doesn't exist" do
      expect { Stripe::Refund.retrieve('nope') }.to raise_error {|e|
        expect(e).to be_a Stripe::InvalidRequestError
        expect(e.param).to eq('refund')
        expect(e.http_status).to eq(404)
      }
    end

    it "updates a stripe charge" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        description: 'Original description',
      })
      original = Stripe::Refund.create(charge: charge.id)
      refund = Stripe::Refund.retrieve(original.id)

      refund.metadata[:order_id] = 6735
      refund.save

      updated = Stripe::Refund.retrieve(original.id)

      expect(updated.metadata.to_hash).to eq(refund.metadata.to_hash)
    end

    it "disallows most parameters on updating a stripe charge" do
      charge = Stripe::Charge.create({
        amount: 777,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        description: 'Original description',
      })
      original = Stripe::Refund.create(charge: charge.id)

      refund = Stripe::Refund.retrieve(original.id)
      refund.reason = "customer changed is mind"
      refund.amount = 777

      expect { refund.save }.to raise_error(Stripe::InvalidRequestError) do |error|
        expect(error.message).to match(/Received unknown parameters/)
        expect(error.message).to match(/reason/)
        expect(error.message).to match(/amount/)
      end
    end

    context "retrieving a list of charges" do
      before do
        customer = Stripe::Customer.create(email: 'johnny@appleseed.com')
        customer2 = Stripe::Customer.create(email: 'johnny2@appleseed.com')
        charge = Stripe::Charge.create(amount: 15, currency: 'usd', customer: customer.id)
        @refund = Stripe::Refund.create(charge: charge.id)
        charge2 = Stripe::Charge.create(amount: 27, currency: 'usd', customer: customer2.id)
        @refund2 = Stripe::Refund.create(charge: charge2.id)
      end

      it "stores all charges in memory" do
        expect(Stripe::Refund.list.data.map(&:id)).to eq([@refund2.id, @refund.id])
      end

      it "defaults count to 10 charges" do
        11.times do
          charge = Stripe::Charge.create(
            amount: 1,
            currency: 'usd',
            source: stripe_helper.generate_card_token
          )
          Stripe::Refund.create(charge: charge.id)
        end

        expect(Stripe::Refund.list.data.count).to eq(10)
      end

      it "is marked as having more when more objects exist" do
        11.times do
          charge = Stripe::Charge.create(
            amount: 1,
            currency: 'usd',
            source: stripe_helper.generate_card_token
          )
          Stripe::Refund.create(charge: charge.id)
        end

        expect(Stripe::Refund.list.has_more).to eq(true)
      end

      context "when passing limit" do
        it "gets that many charges" do
          expect(Stripe::Refund.list(limit: 1).count).to eq(1)
        end
      end
    end

    it 'when use starting_after param', live: true do
      customer = Stripe::Customer.create(
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
        charge = Stripe::Charge.create(
          customer: customer.id,
          amount: 100,
          currency: 'usd'
        )
        Stripe::Refund.create(charge: charge.id)
      end

      all_refunds = Stripe::Refund.list
      default_limit = 10
      half = Stripe::Refund.list(starting_after: all_refunds.data.at(1).id)

      expect(half).to be_a(Stripe::ListObject)
      expect(half.data.count).to eq(default_limit)
      expect(half.data.first.id).to eq(all_refunds.data.at(2).id)
    end

    describe "idempotency" do
      let(:customer) { Stripe::Customer.create(email: 'johnny@appleseed.com') }
      let(:charge) do
        Stripe::Charge.create(
          customer: customer.id,
          amount: 777,
          currency: 'USD',
          capture: true
        )
      end
      let(:refund_params) {{
        charge: charge.id
      }}

      let(:refund_headers) {{
        idempotency_key: 'onceisenough'
      }}

      it "returns the original refund if the same idempotency_key is passed in" do
        refund1 = Stripe::Refund.create(refund_params, refund_headers)
        refund2 = Stripe::Refund.create(refund_params, refund_headers)

        expect(refund1).to eq(refund2)
      end

      context 'different key' do
        let(:different_refund_headers) {{
          idempotency_key: 'thisoneisdifferent'
        }}

        it "returns different charges if different idempotency_keys are used for each charge" do
          refund1 = Stripe::Refund.create(refund_params, refund_headers)
          refund2 = Stripe::Refund.create(refund_params, different_refund_headers)

          expect(refund1).not_to eq(refund2)
        end
      end
    end
  end


  describe 'charge refund API' do

    it "refunds a stripe charge item" do
      charge = Stripe::Charge.create(
        amount: 999,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        description: 'card charge'
      )

      Stripe::Refund.create(charge: charge.id, amount: 999)
      charge.refresh

      expect(charge.refunded).to eq(true)
      expect(charge.refunds.data.first.amount).to eq(999)
      expect(charge.amount_refunded).to eq(999)
    end

    it "creates a stripe refund with the charge ID", :live => true do
      charge = Stripe::Charge.create(
        amount: 999,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        description: 'card charge'
      )
      refund = Stripe::Refund.create(charge: charge.id)

      expect(charge.id).to match(/^(test_)?ch/)
      expect(refund.charge).to eq(charge.id)
    end

    it "creates a stripe refund with a refund ID" do
      charge = Stripe::Charge.create(
        amount: 999,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        description: 'card charge'
      )

      Stripe::Refund.create(charge: charge.id)
      refunds = Stripe::Refund.list(charge: charge.id)

      expect(refunds.data.count).to eq 1
      expect(refunds.data.first.id).to match(/^test_re/)
    end

    it "creates a stripe refund with a status" do
      charge = Stripe::Charge.create(
        amount: 999,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        description: 'card charge'
      )

      Stripe::Refund.create(charge: charge.id)
      refunds = Stripe::Refund.list(charge: charge.id)

      expect(refunds.data.count).to eq 1
      expect(refunds.data.first.status).to eq("succeeded")
    end

    it "creates a stripe refund with a different balance transaction than the charge" do
      charge = Stripe::Charge.create(
        amount: 999,
        currency: 'USD',
        source: stripe_helper.generate_card_token,
        description: 'card charge'
      )
      Stripe::Refund.create(charge: charge.id)
      refunds = Stripe::Refund.list(charge: charge.id)

      expect(charge.balance_transaction).not_to eq(refunds.data.first.balance_transaction)
    end

    it "creates a refund off a charge", :live => true do
      original = Stripe::Charge.create(amount: 555, currency: 'USD', source: stripe_helper.generate_card_token)

      charge = Stripe::Charge.retrieve(original.id)

      refund = charge.refunds.create(amount: 555)
      expect(refund.amount).to eq 555
      expect(refund.charge).to eq charge.id
    end

    it "handles multiple refunds", :live => true do
      original = Stripe::Charge.create(amount: 1100, currency: 'USD', source: stripe_helper.generate_card_token)

      charge = Stripe::Charge.retrieve(original.id)

      refund_1 = charge.refunds.create(amount: 300)
      expect(refund_1.amount).to eq 300
      expect(refund_1.charge).to eq charge.id

      refund_2 = charge.refunds.create(amount: 400)
      expect(refund_2.amount).to eq 400
      expect(refund_2.charge).to eq charge.id

      expect(charge.refunds.count).to eq 0
      expect(charge.refunds.total_count).to eq 0
      expect(charge.amount_refunded).to eq 0

      charge = Stripe::Charge.retrieve(original.id)
      expect(charge.refunds.count).to eq 2
      expect(charge.refunds.total_count).to eq 2
      expect(charge.amount_refunded).to eq 700
    end
  end
end
