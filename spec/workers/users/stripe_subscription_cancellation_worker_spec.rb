require "rails_helper"

RSpec.describe Users::StripeSubscriptionCancellationWorker, type: :worker do
  let(:user) { create(:user, stripe_id_code: "cus_test123") }
  let(:worker) { described_class.new }

  before do
    allow(Settings::General).to receive(:stripe_api_key).and_return("sk_test_123")
  end

  describe "#perform" do
    context "when stripe_customer_id is blank" do
      it "returns early without making Stripe calls" do
        expect(Stripe::Subscription).not_to receive(:list)
        worker.perform(user.id, "")
      end

      it "logs the early return" do
        expect(Rails.logger).not_to receive(:info)
        worker.perform(user.id, nil)
      end
    end

    context "when user has multiple subscriptions with different statuses" do
      let(:active_sub) { double("subscription", id: "sub_active", status: "active") }
      let(:trialing_sub) { double("subscription", id: "sub_trial", status: "trialing") }
      let(:past_due_sub) { double("subscription", id: "sub_past_due", status: "past_due") }
      let(:unpaid_sub) { double("subscription", id: "sub_unpaid", status: "unpaid") }
      let(:canceled_sub) { double("subscription", id: "sub_canceled", status: "canceled") }
      let(:incomplete_sub) { double("subscription", id: "sub_incomplete", status: "incomplete") }
      
      let(:subscriptions_list) do
        double("list", data: [active_sub, trialing_sub, past_due_sub, unpaid_sub, canceled_sub, incomplete_sub])
      end

      before do
        allow(Stripe::Subscription).to receive(:list).with(
          customer: user.stripe_id_code,
          status: "all",
          limit: 100
        ).and_return(subscriptions_list)
      end

      it "cancels only billable subscriptions" do
        expect(Stripe::Subscription).to receive(:update).with("sub_active", { cancel_at_period_end: false })
        expect(Stripe::Subscription).to receive(:update).with("sub_trial", { cancel_at_period_end: false })
        expect(Stripe::Subscription).to receive(:update).with("sub_past_due", { cancel_at_period_end: false })
        expect(Stripe::Subscription).to receive(:update).with("sub_unpaid", { cancel_at_period_end: false })
        
        expect(Stripe::Subscription).not_to receive(:update).with("sub_canceled", anything)
        expect(Stripe::Subscription).not_to receive(:update).with("sub_incomplete", anything)

        worker.perform(user.id, user.stripe_id_code)
      end

      it "logs detailed cancellation summary" do
        allow(Stripe::Subscription).to receive(:update)
        
        expect(Rails.logger).to receive(:info).with("Starting Stripe subscription cancellation for user #{user.id}, customer #{user.stripe_id_code}")
        expect(Rails.logger).to receive(:info).with("Canceling Stripe subscription sub_active (status: active) for user #{user.id}")
        expect(Rails.logger).to receive(:info).with("Canceling Stripe subscription sub_trial (status: trialing) for user #{user.id}")
        expect(Rails.logger).to receive(:info).with("Canceling Stripe subscription sub_past_due (status: past_due) for user #{user.id}")
        expect(Rails.logger).to receive(:info).with("Canceling Stripe subscription sub_unpaid (status: unpaid) for user #{user.id}")
        expect(Rails.logger).to receive(:debug).with("Skipping subscription sub_canceled with status 'canceled' for user #{user.id}")
        expect(Rails.logger).to receive(:debug).with("Skipping subscription sub_incomplete with status 'incomplete' for user #{user.id}")
        expect(Rails.logger).to receive(:info).with("Stripe subscription cancellation completed for user #{user.id}: 4 canceled, 2 skipped")

        worker.perform(user.id, user.stripe_id_code)
      end
    end

    context "when customer not found in Stripe" do
      before do
        allow(Stripe::Subscription).to receive(:list).and_raise(
          Stripe::InvalidRequestError.new("No such customer: #{user.stripe_id_code}", "customer")
        )
      end

      it "logs the expected error and does not raise" do
        expect(Rails.logger).to receive(:info).with("Starting Stripe subscription cancellation for user #{user.id}, customer #{user.stripe_id_code}")
        expect(Rails.logger).to receive(:info).with(/Stripe customer\/subscription not found/)

        expect { worker.perform(user.id, user.stripe_id_code) }.not_to raise_error
      end
    end

    context "when retryable Stripe API error occurs" do
      let(:api_error) { Stripe::APIConnectionError.new("Connection failed") }

      before do
        allow(Stripe::Subscription).to receive(:list).and_raise(api_error)
        allow(worker).to receive(:retryable_stripe_error?).with(api_error).and_return(true)
      end

      it "logs the error and raises for retry when retries not exhausted" do
        allow(worker).to receive(:sidekiq_retries_exhausted?).and_return(false)
        
        expect(Rails.logger).to receive(:error).with(/Stripe API error canceling subscriptions/)
        expect { worker.perform(user.id, user.stripe_id_code) }.to raise_error(Stripe::APIConnectionError)
      end

      it "logs the error and does not raise when retries exhausted" do
        allow(worker).to receive(:sidekiq_retries_exhausted?).and_return(true)
        
        expect(Rails.logger).to receive(:error).with(/Stripe API error canceling subscriptions/)
        expect(Rails.logger).to receive(:error).with(/Max retries reached/)
        expect { worker.perform(user.id, user.stripe_id_code) }.not_to raise_error
      end
    end

    context "when non-retryable Stripe error occurs" do
      let(:auth_error) { Stripe::AuthenticationError.new("Invalid API key") }

      before do
        allow(Stripe::Subscription).to receive(:list).and_raise(auth_error)
        allow(worker).to receive(:retryable_stripe_error?).with(auth_error).and_return(false)
      end

      it "logs the error and does not raise" do
        expect(Rails.logger).to receive(:error).with(/Stripe API error canceling subscriptions/)
        expect { worker.perform(user.id, user.stripe_id_code) }.not_to raise_error
      end
    end

    context "when unexpected error occurs" do
      before do
        allow(Stripe::Subscription).to receive(:list).and_raise(StandardError.new("Unexpected error"))
      end

      it "logs the error with backtrace and does not raise" do
        expect(Rails.logger).to receive(:error).with(/Unexpected error canceling Stripe subscriptions/)
        expect(Rails.logger).to receive(:error).with(anything) # backtrace

        expect { worker.perform(user.id, user.stripe_id_code) }.not_to raise_error
      end
    end

    context "when no subscriptions exist" do
      let(:empty_list) { double("list", data: []) }

      before do
        allow(Stripe::Subscription).to receive(:list).and_return(empty_list)
      end

      it "completes successfully with zero cancellations" do
        expect(Rails.logger).to receive(:info).with("Starting Stripe subscription cancellation for user #{user.id}, customer #{user.stripe_id_code}")
        expect(Rails.logger).to receive(:info).with("Stripe subscription cancellation completed for user #{user.id}: 0 canceled, 0 skipped")

        worker.perform(user.id, user.stripe_id_code)
      end
    end
  end

  describe "#retryable_stripe_error?" do
    it "returns true for retryable errors" do
      expect(worker.send(:retryable_stripe_error?, Stripe::APIConnectionError.new)).to be true
      expect(worker.send(:retryable_stripe_error?, Stripe::APIError.new)).to be true
      expect(worker.send(:retryable_stripe_error?, Stripe::RateLimitError.new)).to be true
    end

    it "returns false for non-retryable errors" do
      expect(worker.send(:retryable_stripe_error?, Stripe::AuthenticationError.new)).to be false
      expect(worker.send(:retryable_stripe_error?, Stripe::InvalidRequestError.new)).to be false
      expect(worker.send(:retryable_stripe_error?, StandardError.new)).to be false
    end
  end
end