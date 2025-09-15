require "rails_helper"

RSpec.describe StripeSubscriptionCancellationWorker, type: :worker do
  let(:user) { create(:user, stripe_id_code: "cus_test123") }
  let(:worker) { described_class.new }

  before do
    allow(Settings::General).to receive(:stripe_api_key).and_return("sk_test_123")
  end

  describe "#perform" do
    context "when stripe_id_code is blank" do
      it "returns early without making Stripe calls" do
        expect(Stripe::Subscription).not_to receive(:list)
        worker.perform(user.id, "")
      end
    end

    context "when user has active subscriptions" do
      let(:active_subscription) { double("subscription", id: "sub_123", status: "active") }
      let(:canceled_subscription) { double("subscription", id: "sub_456", status: "canceled") }
      let(:subscriptions_list) { double("list", data: [active_subscription, canceled_subscription]) }

      before do
        allow(Stripe::Subscription).to receive(:list).with(customer: user.stripe_id_code)
                                                     .and_return(subscriptions_list)
      end

      it "cancels only active subscriptions" do
        expect(Stripe::Subscription).to receive(:update).with("sub_123", {
          cancel_at_period_end: false
        })
        expect(Stripe::Subscription).not_to receive(:update).with("sub_456", anything)

        worker.perform(user.id, user.stripe_id_code)
      end

      it "logs successful cancellation" do
        allow(Stripe::Subscription).to receive(:update)
        
        expect(Rails.logger).to receive(:info).with("Canceling Stripe subscription sub_123 for user #{user.id}")
        expect(Rails.logger).to receive(:info).with("Successfully canceled all Stripe subscriptions for user #{user.id}")

        worker.perform(user.id, user.stripe_id_code)
      end
    end

    context "when customer not found in Stripe" do
      before do
        allow(Stripe::Subscription).to receive(:list).and_raise(
          Stripe::InvalidRequestError.new("No such customer", "customer")
        )
      end

      it "logs the expected error and does not raise" do
        expect(Rails.logger).to receive(:info).with(/Stripe customer\/subscription not found/)

        expect { worker.perform(user.id, user.stripe_id_code) }.not_to raise_error
      end
    end

    context "when Stripe API error occurs" do
      before do
        allow(Stripe::Subscription).to receive(:list).and_raise(
          Stripe::APIError.new("API Error")
        )
      end

      it "logs the error and raises for retry" do
        allow(worker).to receive(:attempts).and_return(1)
        
        expect(Rails.logger).to receive(:error).with(/Stripe error canceling subscriptions/)
        expect { worker.perform(user.id, user.stripe_id_code) }.to raise_error(Stripe::APIError)
      end

      it "does not raise after max attempts" do
        allow(worker).to receive(:attempts).and_return(3)
        
        expect(Rails.logger).to receive(:error).with(/Stripe error canceling subscriptions/)
        expect { worker.perform(user.id, user.stripe_id_code) }.not_to raise_error
      end
    end

    context "when unexpected error occurs" do
      before do
        allow(Stripe::Subscription).to receive(:list).and_raise(StandardError.new("Unexpected error"))
      end

      it "logs the error and does not raise" do
        expect(Rails.logger).to receive(:error).with(/Unexpected error canceling Stripe subscriptions/)
        expect(Rails.logger).to receive(:error).with(anything) # backtrace

        expect { worker.perform(user.id, user.stripe_id_code) }.not_to raise_error
      end
    end

    context "with different subscription statuses" do
      let(:active_sub) { double("subscription", id: "sub_active", status: "active") }
      let(:trialing_sub) { double("subscription", id: "sub_trial", status: "trialing") }
      let(:past_due_sub) { double("subscription", id: "sub_past_due", status: "past_due") }
      let(:canceled_sub) { double("subscription", id: "sub_canceled", status: "canceled") }
      let(:incomplete_sub) { double("subscription", id: "sub_incomplete", status: "incomplete") }
      
      let(:subscriptions_list) do
        double("list", data: [active_sub, trialing_sub, past_due_sub, canceled_sub, incomplete_sub])
      end

      before do
        allow(Stripe::Subscription).to receive(:list).and_return(subscriptions_list)
      end

      it "only cancels active, trialing, and past_due subscriptions" do
        expect(Stripe::Subscription).to receive(:update).with("sub_active", anything)
        expect(Stripe::Subscription).to receive(:update).with("sub_trial", anything)
        expect(Stripe::Subscription).to receive(:update).with("sub_past_due", anything)
        expect(Stripe::Subscription).not_to receive(:update).with("sub_canceled", anything)
        expect(Stripe::Subscription).not_to receive(:update).with("sub_incomplete", anything)

        worker.perform(user.id, user.stripe_id_code)
      end
    end
  end
end