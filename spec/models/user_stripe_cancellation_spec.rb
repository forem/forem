require "rails_helper"

RSpec.describe User, type: :model do
  describe "Stripe subscription cancellation on user deletion" do
    let(:user) { create(:user, stripe_id_code: "cus_test123") }

    describe "#cancel_stripe_subscriptions_async" do
      context "when user has stripe_id_code" do
        it "enqueues the cancellation job" do
          expect(StripeSubscriptionCancellationWorker).to receive(:perform_async)
            .with(user.id, user.stripe_id_code)

          user.send(:cancel_stripe_subscriptions_async)
        end

        it "logs successful job enqueuing" do
          allow(StripeSubscriptionCancellationWorker).to receive(:perform_async)
          
          expect(Rails.logger).to receive(:info)
            .with("Enqueued Stripe subscription cancellation job for user #{user.id}")

          user.send(:cancel_stripe_subscriptions_async)
        end
      end

      context "when user has no stripe_id_code" do
        let(:user) { create(:user, stripe_id_code: nil) }

        it "returns early without enqueuing job" do
          expect(StripeSubscriptionCancellationWorker).not_to receive(:perform_async)
          user.send(:cancel_stripe_subscriptions_async)
        end
      end

      context "when job enqueuing fails" do
        before do
          allow(StripeSubscriptionCancellationWorker).to receive(:perform_async)
            .and_raise(StandardError.new("Redis connection failed"))
        end

        it "logs the error but does not raise" do
          expect(Rails.logger).to receive(:error)
            .with("Failed to enqueue Stripe subscription cancellation for user #{user.id}: Redis connection failed")
          expect(Rails.logger).to receive(:error).with(anything) # backtrace

          expect { user.send(:cancel_stripe_subscriptions_async) }.not_to raise_error
        end
      end
    end

    describe "before_destroy callback" do
      it "calls cancel_stripe_subscriptions_async" do
        expect(user).to receive(:cancel_stripe_subscriptions_async)
        user.destroy
      end

      it "does not prevent user deletion if job enqueuing fails" do
        allow(user).to receive(:cancel_stripe_subscriptions_async)
          .and_raise(StandardError.new("Job failed"))

        # User should still be destroyed even if Stripe cancellation fails
        expect { user.destroy }.to change(User, :count).by(-1)
      end

      context "integration test with actual job enqueuing" do
        it "enqueues the job when user is destroyed" do
          expect(StripeSubscriptionCancellationWorker).to receive(:perform_async)
            .with(user.id, user.stripe_id_code)

          user.destroy
        end
      end
    end

    describe "callback order" do
      it "runs cancel_stripe_subscriptions_async before other destroy callbacks" do
        callback_order = []
        
        allow(user).to receive(:cancel_stripe_subscriptions_async) do
          callback_order << :cancel_stripe_subscriptions_async
        end
        
        allow(user).to receive(:remove_from_mailchimp_newsletters) do
          callback_order << :remove_from_mailchimp_newsletters
        end
        
        allow(user).to receive(:destroy_follows) do
          callback_order << :destroy_follows
        end

        user.destroy

        expect(callback_order).to eq([
          :cancel_stripe_subscriptions_async,
          :remove_from_mailchimp_newsletters,
          :destroy_follows
        ])
      end
    end
  end
end