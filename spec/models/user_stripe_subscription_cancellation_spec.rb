require "rails_helper"

RSpec.describe User, type: :model do
  describe "Stripe subscription cancellation on user deletion" do
    let(:user) { create(:user, stripe_id_code: "cus_test123") }

    describe "#enqueue_stripe_subscription_cancellation" do
      context "when user has stripe_id_code" do
        it "enqueues the cancellation job with correct parameters" do
          expect(Users::StripeSubscriptionCancellationWorker).to receive(:perform_async)
            .with(user.id, user.stripe_id_code)

          user.send(:enqueue_stripe_subscription_cancellation)
        end

        it "logs the job enqueuing process" do
          allow(Users::StripeSubscriptionCancellationWorker).to receive(:perform_async)
          
          expect(Rails.logger).to receive(:info)
            .with("Enqueuing Stripe subscription cancellation for user #{user.id} (customer: #{user.stripe_id_code})")
          expect(Rails.logger).to receive(:info)
            .with("Successfully enqueued Stripe subscription cancellation job for user #{user.id}")

          user.send(:enqueue_stripe_subscription_cancellation)
        end
      end

      context "when user has no stripe_id_code" do
        let(:user) { create(:user, stripe_id_code: nil) }

        it "returns early without enqueuing job" do
          expect(Users::StripeSubscriptionCancellationWorker).not_to receive(:perform_async)
          expect(Rails.logger).not_to receive(:info)
          
          user.send(:enqueue_stripe_subscription_cancellation)
        end
      end

      context "when user has blank stripe_id_code" do
        let(:user) { create(:user, stripe_id_code: "") }

        it "returns early without enqueuing job" do
          expect(Users::StripeSubscriptionCancellationWorker).not_to receive(:perform_async)
          user.send(:enqueue_stripe_subscription_cancellation)
        end
      end

      context "when Redis connection fails" do
        before do
          allow(Users::StripeSubscriptionCancellationWorker).to receive(:perform_async)
            .and_raise(Redis::CannotConnectError.new("Connection refused"))
        end

        it "logs the Redis error but does not raise" do
          expect(Rails.logger).to receive(:info).with(/Enqueuing Stripe subscription cancellation/)
          expect(Rails.logger).to receive(:error).with("Redis error enqueuing Stripe cancellation for user #{user.id}: Connection refused")
          expect(Rails.logger).to receive(:error).with("User deletion will continue, but Stripe subscriptions may need manual cleanup")

          expect { user.send(:enqueue_stripe_subscription_cancellation) }.not_to raise_error
        end
      end

      context "when Sidekiq job enqueuing fails" do
        before do
          allow(Users::StripeSubscriptionCancellationWorker).to receive(:perform_async)
            .and_raise(StandardError.new("Queue full"))
        end

        it "logs the error with full details but does not raise" do
          expect(Rails.logger).to receive(:info).with(/Enqueuing Stripe subscription cancellation/)
          expect(Rails.logger).to receive(:error).with(/Failed to enqueue Stripe subscription cancellation/)
          expect(Rails.logger).to receive(:error).with("User deletion will continue, but Stripe subscriptions may need manual cleanup")
          expect(Rails.logger).to receive(:error).with(anything) # backtrace

          expect { user.send(:enqueue_stripe_subscription_cancellation) }.not_to raise_error
        end
      end

      context "when unexpected error occurs" do
        before do
          allow(Users::StripeSubscriptionCancellationWorker).to receive(:perform_async)
            .and_raise(StandardError.new("Unexpected error"))
        end

        it "logs the error with class name and backtrace but does not raise" do
          expect(Rails.logger).to receive(:error).with("Failed to enqueue Stripe subscription cancellation for user #{user.id}: StandardError - Unexpected error")
          expect(Rails.logger).to receive(:error).with("User deletion will continue, but Stripe subscriptions may need manual cleanup")
          expect(Rails.logger).to receive(:error).with(anything) # backtrace

          expect { user.send(:enqueue_stripe_subscription_cancellation) }.not_to raise_error
        end
      end
    end

    describe "before_destroy callback integration" do
      it "calls enqueue_stripe_subscription_cancellation before destruction" do
        expect(user).to receive(:enqueue_stripe_subscription_cancellation).and_call_original
        expect(Users::StripeSubscriptionCancellationWorker).to receive(:perform_async)

        user.destroy
      end

      it "does not prevent user deletion if job enqueuing fails" do
        # The callback itself should handle errors and not raise them
        allow(Users::StripeSubscriptionCancellationWorker).to receive(:perform_async)
          .and_raise(StandardError.new("Job failed"))

        expect(Rails.logger).to receive(:error).with(/Failed to enqueue Stripe subscription cancellation/)
        expect(Rails.logger).to receive(:error).with(/User deletion will continue/)
        expect(Rails.logger).to receive(:error).with(anything) # backtrace

        # User should still be destroyed even if Stripe cancellation fails
        expect { user.destroy! }.to change(User, :count).by(-1)
      end

      context "with actual job enqueuing" do
        it "enqueues the job when user is destroyed" do
          expect(Users::StripeSubscriptionCancellationWorker).to receive(:perform_async)
            .with(user.id, user.stripe_id_code)

          user.destroy
        end

        it "handles job enqueuing failure gracefully during destruction" do
          allow(Users::StripeSubscriptionCancellationWorker).to receive(:perform_async)
            .and_raise(Redis::CannotConnectError.new("Redis down"))

          expect(Rails.logger).to receive(:error).with("Redis error enqueuing Stripe cancellation for user #{user.id}: Redis down")
          expect { user.destroy! }.to change(User, :count).by(-1)
        end
      end
    end

    describe "callback order and prepend behavior" do
      it "runs stripe cancellation first due to prepend: true" do
        callback_order = []
        
        allow(user).to receive(:enqueue_stripe_subscription_cancellation) do
          callback_order << :stripe_cancellation
        end
        
        allow(user).to receive(:remove_from_mailchimp_newsletters) do
          callback_order << :mailchimp_removal
        end
        
        allow(user).to receive(:destroy_follows) do
          callback_order << :destroy_follows
        end

        user.destroy

        expect(callback_order).to eq([
          :stripe_cancellation,
          :destroy_follows,
          :mailchimp_removal
        ])
      end
    end

    describe "edge cases" do
      context "when user has very long stripe_id_code" do
        let(:long_stripe_id) { "cus_" + "a" * 100 }
        let(:user) { create(:user, stripe_id_code: long_stripe_id) }

        it "handles long customer IDs correctly" do
          expect(Users::StripeSubscriptionCancellationWorker).to receive(:perform_async)
            .with(user.id, long_stripe_id)

          user.send(:enqueue_stripe_subscription_cancellation)
        end
      end

      context "when user ID is very large" do
        let(:user) { create(:user, stripe_id_code: "cus_test") }

        before do
          allow(user).to receive(:id).and_return(999_999_999)
        end

        it "handles large user IDs correctly" do
          expect(Users::StripeSubscriptionCancellationWorker).to receive(:perform_async)
            .with(999_999_999, "cus_test")

          user.send(:enqueue_stripe_subscription_cancellation)
        end
      end
    end
  end
end