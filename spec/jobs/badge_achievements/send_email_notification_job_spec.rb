require "rails_helper"

RSpec.describe BadgeAchievements::SendEmailNotificationJob, type: :job do
  include_examples "#enqueues_job", "badge_achievements_send_email_notification", 1

  describe "#perform_now" do
    context "with badge achievement" do
      let_it_be(:badge_achievement) { double }

      before do
        allow(BadgeAchievement).to receive(:find_by).with(id: 1).and_return(badge_achievement)
      end

      it "sends badge email" do
        mailer = double
        allow(mailer).to receive(:deliver_now)
        allow(NotifyMailer).to receive(:new_badge_email).with(badge_achievement).and_return(mailer)

        described_class.perform_now(1)

        expect(NotifyMailer).to have_received(:new_badge_email).with(badge_achievement)
        expect(mailer).to have_received(:deliver_now)
      end
    end

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
  end
end
