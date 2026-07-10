require "rails_helper"

RSpec.describe Users::NotificationSetting do
  let!(:user) { create(:user) }
  let(:notification_setting) { user.notification_setting.reload }

  context "when callbacks are triggered after commit" do
    describe "subscribing to mailchimp newsletter" do
      it "enqueues SubscribeToMailchimpNewsletterWorker when updating email_newsletter to true" do
        sidekiq_assert_enqueued_with(job: Users::SubscribeToMailchimpNewsletterWorker, args: [user.id]) do
          notification_setting.update(email_newsletter: true)
        end
      end

      it "enqueues SubscribeToMailchimpNewsletterWorker when updating email_newsletter to false" do
        notification_setting.update(email_newsletter: true)
        sidekiq_assert_enqueued_jobs(1, only: Users::SubscribeToMailchimpNewsletterWorker) do
          notification_setting.update(email_newsletter: false)
        end
      end

      it "does not enqueue if email is not set" do
        user.update(email: "")
        sidekiq_assert_no_enqueued_jobs(only: Users::SubscribeToMailchimpNewsletterWorker) do
          notification_setting.update(email_newsletter: !notification_setting.email_newsletter)
        end
      end

      it "does not enqueue if Mailchimp is not enabled" do
        allow(Settings::General).to receive(:mailchimp_api_key).and_return(nil)
        sidekiq_assert_no_enqueued_jobs(only: Users::SubscribeToMailchimpNewsletterWorker) do
          notification_setting.update(email_newsletter: !notification_setting.email_newsletter)
        end
      end

      it "does not enqueue without updating email_newsletter" do
        sidekiq_assert_no_enqueued_jobs(only: Users::SubscribeToMailchimpNewsletterWorker) do
          notification_setting.update(email_badge_notifications: !notification_setting.email_badge_notifications)
        end
      end
    end
  end

  describe "newsletter events for the DEV → Core sync" do
    before do
      allow(Trackable::Registry).to receive(:active_names).and_return([:any])
      allow(Trackable::DispatchWorker).to receive(:perform_async)
      Settings::General.customerio_cdp_enabled = true
      FeatureFlag.enable(:dev_core_user_sync, FeatureFlag::Actor[user])
    end

    after { FeatureFlag.remove(:dev_core_user_sync) }

    around { |ex| with_trackable_events { ex.run } }

    it "emits user_newsletter_subscribed when email_newsletter flips on" do
      notification_setting.update!(email_newsletter: true)
      expect(Trackable::DispatchWorker).to have_received(:perform_async)
        .with(anything, "user_newsletter_subscribed", [user.id], anything, anything)
    end

    it "emits user_newsletter_unsubscribed when email_newsletter flips off" do
      notification_setting.update!(email_newsletter: true)
      notification_setting.update!(email_newsletter: false)
      expect(Trackable::DispatchWorker).to have_received(:perform_async)
        .with(anything, "user_newsletter_unsubscribed", [user.id], anything, anything)
    end

    it "does not emit for other notification setting changes" do
      notification_setting.update!(email_badge_notifications: !notification_setting.email_badge_notifications)
      expect(Trackable::DispatchWorker).not_to have_received(:perform_async)
        .with(anything, /user_newsletter/, anything, anything, anything)
    end

    it "does not emit when the sync gates are off" do
      Settings::General.customerio_cdp_enabled = false
      notification_setting.update!(email_newsletter: true)
      expect(Trackable::DispatchWorker).not_to have_received(:perform_async)
    end
  end
end
