require "rails_helper"

RSpec.describe Users::CancelStripeSubscriptions do
  let(:user) { create(:user, stripe_id_code: "cus_test123") }
  let(:stripe_subscription) { double("Stripe::Subscription", id: "sub_test123") }
  let(:stripe_subscriptions) { double("Stripe::ListObject", data: [stripe_subscription]) }

  before do
    allow(Settings::General).to receive(:stripe_api_key).and_return("sk_test_123")
    allow(Stripe).to receive(:api_key=)
    allow(Stripe::Subscription).to receive(:list).and_return(stripe_subscriptions)
    allow(Stripe::Subscription).to receive(:update)
    allow(Rails.logger).to receive(:info)
    allow(Rails.logger).to receive(:error)
    allow(ForemStatsClient).to receive(:increment)
  end

  describe ".call" do
    it "cancels all active Stripe subscriptions for the user" do
      expect(Stripe::Subscription).to receive(:list).with(
        customer: user.stripe_id_code,
        status: "active"
      ).and_return(stripe_subscriptions)

      expect(Stripe::Subscription).to receive(:update).with(
        stripe_subscription.id,
        { cancel_at_period_end: false }
      )

      described_class.call(user)
    end

    it "logs successful cancellation" do
      described_class.call(user)

      expect(Rails.logger).to have_received(:info).with(
        "Successfully cancelled Stripe subscription #{stripe_subscription.id} for user #{user.id}"
      )
      expect(ForemStatsClient).to have_received(:increment).with(
        "users.stripe_subscription_cancelled",
        tags: ["user_id:#{user.id}"]
      )
    end

    context "when user has no stripe_id_code" do
      let(:user) { create(:user, stripe_id_code: nil) }

      it "does not attempt to cancel subscriptions" do
        expect(Stripe::Subscription).not_to receive(:list)
        described_class.call(user)
      end
    end

    context "when user is nil" do
      it "does not attempt to cancel subscriptions" do
        expect(Stripe::Subscription).not_to receive(:list)
        described_class.call(nil)
      end
    end

    context "when Stripe API returns an error" do
      before do
        allow(Stripe::Subscription).to receive(:list).and_raise(Stripe::InvalidRequestError.new("Customer not found", "customer"))
      end

      it "logs the error but does not raise it" do
        expect { described_class.call(user) }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with(
          "Stripe invalid request error for user #{user.id}: Customer not found"
        )
      end
    end

    context "when subscription cancellation fails" do
      before do
        allow(Stripe::Subscription).to receive(:update).and_raise(Stripe::InvalidRequestError.new("Subscription not found", "subscription"))
      end

      it "logs the error but continues with other subscriptions" do
        expect { described_class.call(user) }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with(
          "Failed to cancel subscription #{stripe_subscription.id} for user #{user.id}: Subscription not found"
        )
      end
    end

    context "when any other error occurs" do
      before do
        allow(Stripe::Subscription).to receive(:list).and_raise(StandardError.new("Unexpected error"))
      end

      it "logs the error but does not raise it" do
        expect { described_class.call(user) }.not_to raise_error
        expect(Rails.logger).to have_received(:error).with(
          "Failed to cancel Stripe subscriptions for user #{user.id}: Unexpected error"
        )
        expect(ForemStatsClient).to have_received(:increment).with(
          "users.stripe_subscription_cancellation_failed",
          tags: ["user_id:#{user.id}"]
        )
      end
    end
  end
end
