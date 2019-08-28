require "rails_helper"

RSpec.describe Comments::CalculateScoreJob, type: :job do
  describe "#perform_now" do
    let(:article) { FactoryBot.create(:article) }
    let(:comment) { FactoryBot.create(:comment, commentable: article) }

    it "updates score and spaminess_rating" do
      allow(BlackBox).to receive(:calculate_spaminess).and_return(7)
      allow(BlackBox).to receive(:comment_quality_score).and_return(99)

      described_class.perform_now(comment.id) do
        expect(comment.score).to be(7)
        expect(comment.spaminess_rating).to be(99)
      end
    end
  end
end
