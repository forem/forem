require "rails_helper"

RSpec.describe Follows::SendEmailNotificationWorker, type: :worker do
  let(:worker) { subject }
  let(:mailer_class) { NotifyMailer }
  let(:mailer) { double }
  let(:message_delivery) { double }

  let(:user) { create(:user) }
  let(:user2) { create(:user) }

  describe "#perform" do
    before do
      allow(mailer_class).to receive(:with).and_return(mailer)
      allow(mailer).to receive(:new_follower_email).and_return(message_delivery)
      allow(message_delivery).to receive(:deliver_now)
    end

    context "with follow" do
      it "sends a new_follower_email" do
        user2.notification_setting.update(email_follower_notifications: true)
        follow = user.follow(user2)

        sidekiq_perform_enqueued_jobs(only: described_class)

        expect(mailer_class).to have_received(:with).with(follow: follow)
        expect(mailer).to have_received(:new_follower_email)
        expect(message_delivery).to have_received(:deliver_now)
      end

      it "doesn't send an email if user has disabled notifications" do
        user2.notification_setting.update(email_follower_notifications: false)
        follow = user.follow(user2)

        sidekiq_perform_enqueued_jobs(only: described_class)

        expect(mailer_class).not_to have_received(:with).with(follow: follow)
        expect(mailer).not_to have_received(:new_follower_email)
        expect(message_delivery).not_to have_received(:deliver_now)
      end

      it "doesn't create an EmailMessage if it already exists" do
        subject = "#{user.username} just followed you on #{ApplicationConfig['COMMUNITY_NAME']}"
        EmailMessage.create!(user_id: user2.id, sent_at: Time.current, subject: subject)

        user2.notification_setting.update(email_follower_notifications: false)
        follow = user.follow(user2)

        sidekiq_perform_enqueued_jobs(only: described_class)

        expect(mailer_class).not_to have_received(:with).with(follow: follow)
        expect(mailer).not_to have_received(:new_follower_email)
        expect(message_delivery).not_to have_received(:deliver_now)
      end
    end

    context "without follow" do
      it "does not break" do
        expect do
          described_class.perform_async(nil)
          sidekiq_perform_enqueued_jobs(only: described_class)
        end.not_to raise_error
      end
    end
  end
end
