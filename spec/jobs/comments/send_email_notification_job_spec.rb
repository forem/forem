require "rails_helper"

RSpec.describe Comments::SendEmailNotificationJob, type: :job do
  describe "#perform_now" do
    let(:article) { FactoryBot.create(:article) }
    let(:comment) { FactoryBot.create(:comment, commentable: article) }

    it "sends notify email" do
      allow(NotifyMailer).to receive(:new_reply_email)

      described_class.perform_now(comment.id) do
        expect(NotifyMailer).to have_receive(:new_reply_email).with(comment).and_call_original
      end
    end
  end
end
