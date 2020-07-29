require "rails_helper"

RSpec.describe BadgeAchievements::SendEmailNotificationWorker, type: :worker do
  let(:worker) { subject }
  let(:mailer_class) { NotifyMailer }
  let(:mailer) { double }
  let(:message_delivery) { double }

  # passing in a random badge_achievement_id argument since the worker itself won't be executed
  include_examples "#enqueues_on_correct_queue", "low_priority", [456]

  describe "#perform_now" do
    before do
      allow(mailer_class).to receive(:with).and_return(mailer)
      allow(mailer).to receive(:new_badge_email).and_return(message_delivery)
      allow(message_delivery).to receive(:deliver_now)
    end

    context "with badge achievement" do
      let(:badge_achievement) { double }

      before do
        allow(BadgeAchievement).to receive(:find_by).with(id: 1).and_return(badge_achievement)
      end

      it "sends badge email" do
        worker.perform(1)

        expect(mailer_class).to have_received(:with).with(badge_achievement: badge_achievement)
        expect(mailer).to have_received(:new_badge_email)
        expect(message_delivery).to have_received(:deliver_now)
      end
    end

    context "without badge achievement" do
      it "does not error" do
        expect { worker.perform(nil) }.not_to raise_error
      end

      it "does not call NotifyMailer" do
        worker.perform(nil)

        expect(mailer).not_to have_received(:new_badge_email)
      end
    end
  end
end
