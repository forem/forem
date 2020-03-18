require "rails_helper"

class MockMailer
  def self.deliver; end
end

RSpec.describe Follows::SendEmailNotificationWorker, type: :worker do
  subject(:worker) { described_class }

  let_it_be(:user) { create(:user) }
  let_it_be(:user2) { create(:user) }
  let_it_be(:follow) { create(:follow, follower: user, followable: user2) }

  describe "#perform" do
    before do
      allow(NotifyMailer).to receive(:new_follower_email).and_return(MockMailer)
      allow(MockMailer).to receive(:deliver)
      worker.perform_async(follow_id)
    end

    context "with follow" do
      let(:follow_id) { follow.id }

      it "sends a new_follower_email" do
        user2.update_column(:email_follower_notifications, true)
        worker.drain

        expect(MockMailer).to have_received(:deliver).once
      end

      it "doesn't send an email if user has disabled notifications" do
        user2.update_column(:email_follower_notifications, false)
        worker.drain

        expect(MockMailer).not_to have_received(:deliver)
      end

      it "doesn't create an EmailMessage if it already exists" do
        subject = "#{user.username} just followed you on dev.to"
        EmailMessage.create!(user_id: user2.id, sent_at: Time.current, subject: subject)

        worker.drain

        expect(MockMailer).not_to have_received(:deliver)
      end
    end

    context "without follow" do
      let(:follow_id) { nil }

      it "does not break" do
        expect { worker.drain }.not_to raise_error
      end
    end
  end
end
