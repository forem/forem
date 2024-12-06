require 'spec_helper'
require 'pp'

shared_examples 'Dispute API' do

  let(:stripe_helper) { StripeMock.create_test_helper }

  it "returns an error if dispute does not exist" do
    dispute_id = 'dp_xxxxxxxxxxxxxxxxxxxxxxxx'

    expect {
      Stripe::Dispute.retrieve(dispute_id)
    }.to raise_error { |e|
      expect(e).to be_a(Stripe::InvalidRequestError)
      expect(e.message).to eq('No such dispute: ' + dispute_id)
    }
  end

  it "retrieves a single dispute" do
    dispute_id = 'dp_05RsQX2eZvKYlo2C0FRTGSSA'
    dispute = Stripe::Dispute.retrieve(dispute_id)

    expect(dispute).to be_a(Stripe::Dispute)
    expect(dispute.id).to eq(dispute_id)
  end

  it "updates a dispute" do
    dispute_id = 'dp_65RsQX2eZvKYlo2C0ASDFGHJ'
    dispute = Stripe::Dispute.retrieve(dispute_id)

    expect(dispute).to be_a(Stripe::Dispute)
    expect(dispute.id).to eq(dispute_id)
    expect(dispute.evidence.customer_name).to eq(nil)
    expect(dispute.evidence.product_description).to eq(nil)
    expect(dispute.evidence.shipping_documentation).to eq(nil)

    dispute.evidence = {
      :customer_name => 'Rebel Idealist',
      :product_description => 'Lorem ipsum dolor sit amet.',
      :shipping_documentation => 'fil_15BZxW2eZvKYlo2CvQbrn9dc',
    }
    dispute.save

    dispute = Stripe::Dispute.retrieve(dispute_id)

    expect(dispute).to be_a(Stripe::Dispute)
    expect(dispute.id).to eq(dispute_id)
    expect(dispute.evidence.customer_name).to eq('Rebel Idealist')
    expect(dispute.evidence.product_description).to eq('Lorem ipsum dolor sit amet.')
    expect(dispute.evidence.shipping_documentation).to eq('fil_15BZxW2eZvKYlo2CvQbrn9dc')
  end

  it "closes a dispute" do
    dispute_id = 'dp_75RsQX2eZvKYlo2C0EDCXSWQ'

    dispute = Stripe::Dispute.retrieve(dispute_id)

    expect(dispute).to be_a(Stripe::Dispute)
    expect(dispute.id).to eq(dispute_id)
    expect(dispute.status).to eq('under_review')

    dispute.close

    dispute = Stripe::Dispute.retrieve(dispute_id)

    expect(dispute).to be_a(Stripe::Dispute)
    expect(dispute.id).to eq(dispute_id)
    expect(dispute.status).to eq('lost')
  end

  describe "listing disputes" do

    it "retrieves all disputes" do
      disputes = Stripe::Dispute.list

      expect(disputes.count).to eq(10)
      expect(disputes.map &:id).to include('dp_05RsQX2eZvKYlo2C0FRTGSSA','dp_15RsQX2eZvKYlo2C0ERTYUIA', 'dp_25RsQX2eZvKYlo2C0ZXCVBNM', 'dp_35RsQX2eZvKYlo2C0QAZXSWE', 'dp_45RsQX2eZvKYlo2C0EDCVFRT', 'dp_55RsQX2eZvKYlo2C0OIKLJUY', 'dp_65RsQX2eZvKYlo2C0ASDFGHJ', 'dp_75RsQX2eZvKYlo2C0EDCXSWQ', 'dp_85RsQX2eZvKYlo2C0UJMCDET', 'dp_95RsQX2eZvKYlo2C0EDFRYUI')
    end

    it "retrieves disputes with a limit(3)" do
      disputes = Stripe::Dispute.list(limit: 3)

      expect(disputes.count).to eq(3)
      expected = ['dp_95RsQX2eZvKYlo2C0EDFRYUI','dp_85RsQX2eZvKYlo2C0UJMCDET', 'dp_75RsQX2eZvKYlo2C0EDCXSWQ']
      expect(disputes.map &:id).to include(*expected)
    end

  end

  it "creates a dispute" do
    card_token = stripe_helper.generate_card_token(last4: "1123", exp_month: 11, exp_year: 2099)
    charge = Stripe::Charge.create(amount: 1000, currency: "usd", source: card_token)
    stripe_dispute_id = stripe_helper.upsert_stripe_object(:dispute, {amount: charge.amount, charge: charge.id})
    stripe_dispute = Stripe::Dispute.retrieve(stripe_dispute_id)
    expect(stripe_dispute.charge).to eq(charge.id)
  end

end
