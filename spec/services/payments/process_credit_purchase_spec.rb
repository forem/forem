require "rails_helper"

RSpec.describe Payments::ProcessCreditPurchase, type: :service do
  describe ".call" do
    let(:purchase_options) { {} }

    it "sets error if no payment method" do
      purchase = described_class.call(:nouser, :nocredits, purchase_options: purchase_options)

      expect(purchase.error).to eq(I18n.t("services.payments.errors.select_payment_method"))
    end

    context "when a payment error occurs" do
      let(:customer) { Stripe::Customer.create }
      let(:user) { instance_double(User, id: :id, stripe_id_code: customer.id) }
      let(:purchase_options) { { stripe_token: :token } }

      before do
        StripeMock.start
      end

      after do
        StripeMock.stop
      end

      it "sets error if less than 1 credit ordered" do
        purchase = described_class.call(user, 0, purchase_options: purchase_options)

        expect(purchase.error).to eq("Invalid positive integer")
      end

      it "sets error if payment error is raised" do
        # this customer get call is the first thing call does
        allow(Payments::Customer)
          .to receive(:get)
          .with(customer.id)
          .and_raise(Payments::PaymentsError, "Message")

        purchase = described_class.call(user, 1, purchase_options: purchase_options)

        expect(purchase.error).to eq("Message")
      end
    end
  end
end
