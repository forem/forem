require "rails_helper"

RSpec.describe BadgeAchievements::SendEmailNotificationJob, type: :job do
  let(:user) { create(:user, email_badge_notifications: true) }
  let(:badge_achievement) { create(:badge_achievement, user: user) }

  describe ".perform_later" do
    it "add job to the queue :badge_achievements_send_email_notification" do
      expect do
        described_class.perform_later(1)
      end.to have_enqueued_job.with(1).on_queue("badge_achievements_send_email_notification")
    end
  end

  describe "#perform" do
    it "calls on NotifyMailer" do
      described_class.new.perform(badge_achievement.id) do
        expect(NotifyMailer).to have_received(:new_badge_email).with(badge_achievement)
      end
    end
  end
end
