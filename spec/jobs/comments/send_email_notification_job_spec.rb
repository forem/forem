require "rails_helper"

RSpec.describe Comments::SendEmailNotificationJob, type: :job do
  describe "#perform_now" do
    let(:article) { FactoryBot.create(:article) }
    let(:comment) { FactoryBot.create(:comment, commentable: article) }

    it "creates an id code" do
      allow(NotifyMailer).to receive(:new_reply)

      described_class.perform_now(comment.id) do
        expect(NotifyMailer).to have_receive(:new_reply).with(comment)
      end
    end
  end
end
