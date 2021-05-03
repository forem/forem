require "rails_helper"

RSpec.describe Articles::ScoreCalcWorker, type: :worker do
  let(:worker) { subject }

  # Passing in a random article_id since the worker doesn't actually run
  include_examples "#enqueues_on_correct_queue", "medium_priority", [456]

  describe "#perform_now" do
    before do
      allow(BlackBox).to receive(:article_hotness_score).and_return(373)
      allow(BlackBox).to receive(:calculate_spaminess).and_return(2)
    end

    context "with article" do
      let(:article) { create(:article) }
      let(:comment) { create(:comment, commentable: article, score: 5) }
      let(:second_comment) { create(:comment, commentable: article, score: 7) }

      before { [comment, second_comment] }

      it "updates article scores", :aggregate_failures do
        allow(Article).to receive(:find_by).and_return(article)
        allow(article.reactions).to receive(:sum).and_return(7)

        worker.perform(article.id)
        article.reload

        expect(article.score).to be(7)
        expect(article.comment_score).to be(12)
        expect(article.hotness_score).to be(373)
        expect(article.spaminess_rating).to be(2)
      end
    end

    context "without article" do
      it "does not error" do
        expect { worker.perform(nil) }.not_to raise_error
      end

      it "does not calculate scores", :aggregate_failures do
        worker.perform(nil)

        expect(BlackBox).not_to have_received(:article_hotness_score)
        expect(BlackBox).not_to have_received(:calculate_spaminess)
      end
    end
  end
end
