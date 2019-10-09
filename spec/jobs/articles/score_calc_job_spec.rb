require "rails_helper"

RSpec.describe Articles::ScoreCalcJob, type: :job do
  include_examples "#enqueues_job", "articles_score_calc", 1

  describe "#perform_now" do
    let(:article) { FactoryBot.create(:article) }

    before do
      allow(BlackBox).to receive(:article_hotness_score).and_return(373)
      allow(BlackBox).to receive(:calculate_spaminess).and_return(2)
    end

    it "updates article scores", :aggregate_failures do
      allow(Article).to receive(:find_by).and_return(article)
      allow(article.reactions).to receive(:sum).and_return(7)
      described_class.perform_now(article.id)
      article.reload
      expect(article.score).to be(7)
      expect(article.hotness_score).to be(373)
      expect(article.spaminess_rating).to be(2)
    end

    context "without article" do
      it "does not error" do
        expect { described_class.perform_now(nil) }.not_to raise_error
      end

      it "does not calculate scores", :aggregate_failures do
        described_class.perform_now(nil)
        expect(BlackBox).not_to have_received(:article_hotness_score)
        expect(BlackBox).not_to have_received(:calculate_spaminess)
      end
    end
  end
end
