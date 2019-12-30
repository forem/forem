require "rails_helper"

RSpec.describe BadgeAchievements::SendEmailNotificationJob, type: :job do
  include_examples "#enqueues_job", "badge_achievements_send_email_notification", 1

  describe "#perform_now" do
    context "without badge achievement" do
      it "does not error" do
        expect { described_class.perform_now(nil) }.not_to raise_error
      end

      it "does not call NotifyMailer" do
        allow(NotifyMailer).to receive(:new_badge_email)

        described_class.perform_now(nil)

        expect(NotifyMailer).not_to have_received(:new_badge_email)
      end
    end

    context "with badge achievement" do
      let_it_be(:badge_achievement) { create(:badge_achievement) }

      it "calls on NotifyMailer" do
        mailer = double
        allow(mailer).to receive(:deliver_now)
        allow(NotifyMailer).to receive(:new_badge_email).with(badge_achievement).and_return(mailer)

        described_class.perform_now(badge_achievement.id)

        expect(NotifyMailer).to have_received(:new_badge_email).with(badge_achievement)
        expect(mailer).to have_received(:deliver_now)
      end
    end
  end
end
