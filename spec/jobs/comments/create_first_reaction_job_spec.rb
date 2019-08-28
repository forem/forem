require "rails_helper"

RSpec.describe Comments::CreateFirstReactionJob, type: :job do
  describe "#perform_now" do
    let(:article) { FactoryBot.create(:article) }
    let(:comment) { FactoryBot.create(:comment, commentable: article) }

    it "creates a first reaction" do
      expect do
        described_class.perform_now(comment.id)
      end.to change(Reaction, :count).by(1)
    end
  end
end
