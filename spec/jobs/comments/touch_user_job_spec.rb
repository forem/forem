require "rails_helper"

RSpec.describe Comments::TouchUserJob, type: :job do
  describe "#perform_now" do
    let(:article) { FactoryBot.create(:article) }
    let(:comment) { FactoryBot.create(:comment, commentable: article) }

    it "touches user updated_at and last_comment_at columns" do
      allow(comment.user).to receive(:touch)

      described_class.perform_now(comment.id) do
        expect(comment.user).to have_receive(:touch).with(:updated_at, :last_comment_at)
      end
    end
  end
end
