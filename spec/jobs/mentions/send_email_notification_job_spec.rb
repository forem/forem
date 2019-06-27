require "rails_helper"

RSpec.describe Mentions::SendEmailNotificationJob do
  let(:user) { create(:user) }
  let(:mention) { create(:mention, user_id: user.id, mentionable_id: comment.id, mentionable_type: "Comment") }
  let(:comment) { create(:comment, user_id: user.id, commentable: create(:article)) }

  describe ".perform_later" do
    it "add job to queue :mentions_send_email_notification" do
      expect do
        described_class.perform_later(1)
      end.to have_enqueued_job.with(1).on_queue("mentions_send_email_notification")
    end
  end

  describe "#perform" do
    it "calls on NotifyMailer" do
      described_class.new.perform(mention.id) do
        expect(NotifyMailer).to have_received(:new_mention_email).with(mention)
      end
    end
  end
end
