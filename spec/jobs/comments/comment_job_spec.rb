require "rails_helper"

RSpec.describe Comments::CommentJob, type: :job do
  describe "#perform_now" do
    let(:article) { FactoryBot.create(:article) }
    let(:comment) { FactoryBot.create(:comment, commentable: article) }

    it "performs method on comment" do
      described_class.perform_now(comment.id, "send_email_notification") do
        expect(comment).to have_receive(:send_email_notification)
      end
    end

    it "does not perform method when no comment" do
      described_class.perform_now(9999, "send_email_notification") do
        expect(comment).not_to have_receive(:send_email_notification)
      end
    end
  end
end
