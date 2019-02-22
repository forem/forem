require "rails_helper"

RSpec.describe Follows::SendEmailNotificationJob, type: :job do
  describe "#perform_later" do
    it "enqueues the job" do
      ActiveJob::Base.queue_adapter = :test
      expect do
        described_class.perform_later(3)
      end.to have_enqueued_job.with(3).on_queue("send_follow_email_notification")
    end
  end

  describe "#perform_now" do
    let(:user) { create(:user) }
    let(:user2) { create(:user) }
    let!(:follow) { create(:follow, follower: user, followable: user2) }
    let(:mailer) { double }

    before do
      deliverer = double
      allow(deliverer).to receive(:deliver)
      allow(mailer).to receive(:new_follower_email).and_return(deliverer)
    end

    it "sends a new_follower_email" do
      user2.update_column(:email_follower_notifications, true)
      described_class.new(follow.id, mailer).perform_now
      expect(mailer).to have_received(:new_follower_email).once
    end

    it "doesn't create an EmailMessage if it already exists" do
      EmailMessage.create!(user_id: user2.id, sent_at: Time.now, subject: "#{user.username} followed you on dev.to")
      described_class.new(follow.id, mailer).perform_now
      expect(mailer).not_to have_received(:new_follower_email)
    end

    it "doesn't send an email if user has disabled notifications" do
      user2.update_column(:email_follower_notifications, false)
      expect(mailer).not_to have_received(:new_follower_email)
    end

    it "doesn't fail if follow doesn't exist" do
      described_class.perform_now(Follow.maximum(:id).to_i + 1)
    end
  end
end
