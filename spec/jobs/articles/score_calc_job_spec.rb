require "rails_helper"

RSpec.describe Articles::ScoreCalcJob, type: :job do
  include_examples "#enqueues_job", "articles_score_calc", 1

  describe "#perform_now" do
    let(:article) { FactoryBot.create(:article) }

    before do
      allow(article.reactions).to receive(:sum).and_return(7)
      allow(BlackBox).to receive(:article_hotness_score).and_return(373)
      allow(BlackBox).to receive(:calculate_spaminess).and_return(2)
    end

    it "updates article scores" do
      described_class.perform_now(article.id) do
        expect(article.score).to be(7)
        expect(article.hotness_score).to be(373)
        expect(article.spaminess_rating).to be(2)
      end
    end

    it "does not update article scores when no article" do
      described_class.perform_now(article.id) do
        expect(article.score).not_to be(7)
        expect(article.hotness_score).not_to be(373)
        expect(article.spaminess_rating).not_to be(2)
      end
    end
  end
end
