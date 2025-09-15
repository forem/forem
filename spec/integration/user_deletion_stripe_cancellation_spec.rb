require "rails_helper"

RSpec.describe "User deletion with Stripe subscription cancellation", type: :integration do
  let(:user) { create(:user, stripe_id_code: "cus_test123") }

  before do
    allow(Settings::General).to receive(:stripe_api_key).and_return("sk_test_123")
  end

  describe "when user is deleted" do
    context "with active Stripe subscriptions" do
      let(:active_subscription) { double("subscription", id: "sub_123", status: "active") }
      let(:subscriptions_list) { double("list", data: [active_subscription]) }

      before do
        allow(Stripe::Subscription).to receive(:list).with(customer: user.stripe_id_code)
                                                     .and_return(subscriptions_list)
        allow(Stripe::Subscription).to receive(:update)
      end

      it "successfully deletes user and cancels subscriptions" do
        # Verify user deletion works
        expect { user.destroy }.to change(User, :count).by(-1)

        # Verify the job was enqueued (we can't easily test job execution in integration)
        expect(StripeSubscriptionCancellationWorker.jobs.size).to eq(1)
        
        job = StripeSubscriptionCancellationWorker.jobs.last
        expect(job["args"]).to eq([user.id, "cus_test123"])
      end
    end

    context "when Stripe API is unavailable" do
      before do
        # Simulate Sidekiq being unavailable
        allow(StripeSubscriptionCancellationWorker).to receive(:perform_async)
          .and_raise(Redis::CannotConnectError.new("Connection refused"))
      end

      it "still deletes the user successfully" do
        expect(Rails.logger).to receive(:error).with(/Failed to enqueue Stripe subscription cancellation/)
        expect(Rails.logger).to receive(:error).with(anything) # backtrace

        # User deletion should not fail even if job enqueuing fails
        expect { user.destroy }.to change(User, :count).by(-1)
      end
    end

    context "when user has no Stripe ID" do
      let(:user) { create(:user, stripe_id_code: nil) }

      it "deletes user without attempting Stripe cancellation" do
        expect(StripeSubscriptionCancellationWorker).not_to receive(:perform_async)
        expect { user.destroy }.to change(User, :count).by(-1)
      end
    end
  end

  describe "job execution" do
    context "when job runs successfully" do
      let(:active_subscription) { double("subscription", id: "sub_123", status: "active") }
      let(:subscriptions_list) { double("list", data: [active_subscription]) }

      before do
        allow(Stripe::Subscription).to receive(:list).and_return(subscriptions_list)
        allow(Stripe::Subscription).to receive(:update)
      end

      it "cancels all active subscriptions" do
        worker = StripeSubscriptionCancellationWorker.new
        
        expect(Stripe::Subscription).to receive(:update).with("sub_123", {
          cancel_at_period_end: false
        })

        worker.perform(user.id, user.stripe_id_code)
      end
    end

    context "when Stripe customer doesn't exist" do
      before do
        allow(Stripe::Subscription).to receive(:list)
          .and_raise(Stripe::InvalidRequestError.new("No such customer", "customer"))
      end

      it "handles the error gracefully" do
        worker = StripeSubscriptionCancellationWorker.new
        
        expect(Rails.logger).to receive(:info).with(/Stripe customer\/subscription not found/)
        expect { worker.perform(user.id, user.stripe_id_code) }.not_to raise_error
      end
    end
  end
end