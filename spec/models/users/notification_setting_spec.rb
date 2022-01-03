require "rails_helper"

RSpec.describe Users::NotificationSetting, type: :model do
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
end
