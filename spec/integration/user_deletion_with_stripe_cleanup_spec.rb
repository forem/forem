require "rails_helper"

RSpec.describe "User deletion with Stripe subscription cleanup", type: :integration do
  let(:user) { create(:user, stripe_id_code: "cus_integration_test") }

  before do
    allow(Settings::General).to receive(:stripe_api_key).and_return("sk_test_integration")
  end

  describe "complete user deletion flow" do
    context "with active Stripe subscriptions" do
      let(:active_subscription) { double("subscription", id: "sub_active_123", status: "active") }
      let(:trialing_subscription) { double("subscription", id: "sub_trial_456", status: "trialing") }
      let(:subscriptions_list) { double("list", data: [active_subscription, trialing_subscription]) }

      before do
        allow(Stripe::Subscription).to receive(:list).with(
          customer: user.stripe_id_code,
          status: "all",
          limit: 100
        ).and_return(subscriptions_list)
        allow(Stripe::Subscription).to receive(:update)
      end

      it "successfully deletes user and enqueues subscription cancellation" do
        # Verify user deletion works
        expect { user.destroy }.to change(User, :count).by(-1)

        # Verify the job was enqueued
        expect(Users::StripeSubscriptionCancellationWorker.jobs.size).to eq(1)
        
        job = Users::StripeSubscriptionCancellationWorker.jobs.last
        expect(job["args"]).to eq([user.id, "cus_integration_test"])
      end

      it "processes the job correctly when executed" do
        user_id = user.id
        stripe_id = user.stripe_id_code
        
        # Delete the user first
        user.destroy

        # Process the enqueued job
        Users::StripeSubscriptionCancellationWorker.drain

        # Verify Stripe API calls were made
        expect(Stripe::Subscription).to have_received(:list).with(
          customer: stripe_id,
          status: "all",
          limit: 100
        )
        expect(Stripe::Subscription).to have_received(:update).with("sub_active_123", { cancel_at_period_end: false })
        expect(Stripe::Subscription).to have_received(:update).with("sub_trial_456", { cancel_at_period_end: false })
      end
    end

    context "when Stripe API is completely unavailable" do
      before do
        allow(Stripe::Subscription).to receive(:list)
          .and_raise(Stripe::APIConnectionError.new("Service unavailable"))
      end

      it "still deletes the user successfully" do
        expect { user.destroy }.to change(User, :count).by(-1)

        # Job should be enqueued but will fail when processed
        expect(Users::StripeSubscriptionCancellationWorker.jobs.size).to eq(1)
      end

      it "handles API failure gracefully in job processing" do
        user_id = user.id
        user.destroy

        # Process the job - should not raise error
        expect { Users::StripeSubscriptionCancellationWorker.drain }.not_to raise_error
      end
    end

    context "when Redis/Sidekiq is unavailable" do
      before do
        allow(Users::StripeSubscriptionCancellationWorker).to receive(:perform_async)
          .and_raise(Redis::CannotConnectError.new("Connection refused"))
      end

      it "still deletes the user successfully" do
        expect(Rails.logger).to receive(:error).with(/Redis error enqueuing Stripe cancellation/)
        expect(Rails.logger).to receive(:error).with(/User deletion will continue/)

        # User deletion should not fail even if job enqueuing fails
        expect { user.destroy }.to change(User, :count).by(-1)
      end
    end

    context "when user has no Stripe customer ID" do
      let(:user) { create(:user, stripe_id_code: nil) }

      it "deletes user without attempting Stripe operations" do
        expect(Users::StripeSubscriptionCancellationWorker).not_to receive(:perform_async)
        expect { user.destroy }.to change(User, :count).by(-1)
      end
    end

    context "when user has empty Stripe customer ID" do
      let(:user) { create(:user, stripe_id_code: "") }

      it "deletes user without attempting Stripe operations" do
        expect(Users::StripeSubscriptionCancellationWorker).not_to receive(:perform_async)
        expect { user.destroy }.to change(User, :count).by(-1)
      end
    end
  end

  describe "job processing scenarios" do
    let(:worker) { Users::StripeSubscriptionCancellationWorker.new }

    context "with mixed subscription statuses" do
      let(:subscriptions) do
        [
          double("sub1", id: "sub_active", status: "active"),
          double("sub2", id: "sub_canceled", status: "canceled"),
          double("sub3", id: "sub_trialing", status: "trialing"),
          double("sub4", id: "sub_incomplete", status: "incomplete"),
          double("sub5", id: "sub_past_due", status: "past_due")
        ]
      end
      let(:subscriptions_list) { double("list", data: subscriptions) }

      before do
        allow(Stripe::Subscription).to receive(:list).and_return(subscriptions_list)
        allow(Stripe::Subscription).to receive(:update)
      end

      it "cancels only the appropriate subscriptions" do
        worker.perform(user.id, user.stripe_id_code)

        # Should cancel: active, trialing, past_due
        expect(Stripe::Subscription).to have_received(:update).with("sub_active", { cancel_at_period_end: false })
        expect(Stripe::Subscription).to have_received(:update).with("sub_trialing", { cancel_at_period_end: false })
        expect(Stripe::Subscription).to have_received(:update).with("sub_past_due", { cancel_at_period_end: false })

        # Should NOT cancel: canceled, incomplete
        expect(Stripe::Subscription).not_to have_received(:update).with("sub_canceled", anything)
        expect(Stripe::Subscription).not_to have_received(:update).with("sub_incomplete", anything)
      end
    end

    context "when customer has many subscriptions" do
      let(:many_subscriptions) do
        (1..50).map do |i|
          double("sub#{i}", id: "sub_#{i}", status: "active")
        end
      end
      let(:subscriptions_list) { double("list", data: many_subscriptions) }

      before do
        allow(Stripe::Subscription).to receive(:list).and_return(subscriptions_list)
        allow(Stripe::Subscription).to receive(:update)
      end

      it "handles large numbers of subscriptions" do
        worker.perform(user.id, user.stripe_id_code)

        # Should have called update for each active subscription
        expect(Stripe::Subscription).to have_received(:update).exactly(50).times
      end
    end

    context "when individual subscription cancellation fails" do
      let(:subscriptions) do
        [
          double("sub1", id: "sub_good", status: "active"),
          double("sub2", id: "sub_bad", status: "active")
        ]
      end
      let(:subscriptions_list) { double("list", data: subscriptions) }

      before do
        allow(Stripe::Subscription).to receive(:list).and_return(subscriptions_list)
        allow(Stripe::Subscription).to receive(:update).with("sub_good", anything)
        allow(Stripe::Subscription).to receive(:update).with("sub_bad", anything)
          .and_raise(Stripe::InvalidRequestError.new("Subscription already canceled"))
      end

      it "continues processing other subscriptions" do
        # Should not raise error despite one subscription failing
        expect { worker.perform(user.id, user.stripe_id_code) }.not_to raise_error

        # Should have attempted both
        expect(Stripe::Subscription).to have_received(:update).with("sub_good", anything)
        expect(Stripe::Subscription).to have_received(:update).with("sub_bad", anything)
      end
    end
  end

  describe "logging and monitoring" do
    let(:active_sub) { double("subscription", id: "sub_123", status: "active") }
    let(:canceled_sub) { double("subscription", id: "sub_456", status: "canceled") }
    let(:subscriptions_list) { double("list", data: [active_sub, canceled_sub]) }

    before do
      allow(Stripe::Subscription).to receive(:list).and_return(subscriptions_list)
      allow(Stripe::Subscription).to receive(:update)
    end

    it "provides comprehensive logging throughout the process" do
      # User deletion logging
      expect(Rails.logger).to receive(:info).with(/Enqueuing Stripe subscription cancellation/)
      expect(Rails.logger).to receive(:info).with(/Successfully enqueued/)

      user.destroy

      # Job processing logging
      expect(Rails.logger).to receive(:info).with(/Starting Stripe subscription cancellation/)
      expect(Rails.logger).to receive(:info).with(/Canceling Stripe subscription sub_123/)
      expect(Rails.logger).to receive(:debug).with(/Skipping subscription sub_456/)
      expect(Rails.logger).to receive(:info).with(/Stripe subscription cancellation completed.*1 canceled, 1 skipped/)

      Users::StripeSubscriptionCancellationWorker.drain
    end
  end
end