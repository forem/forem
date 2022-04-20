require "rails_helper"

RSpec.describe Moderator::SinkArticlesWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "medium_priority", 1

  describe "#perform" do
    it "returns early when user not found" do
      expect { described_class.new.perform(nil) }.not_to raise_error
      expect(described_class.new.perform(nil)).to be_nil
    end

    it "updates score for user's articles" do
      article = create(:article, score: 20.0)
      # flagging a user is the normal route to sink articles,
      # and ensures score changes in an observable manner
      create(:vomit_reaction, reactable: article.user)
      allow(BlackBox).to receive(:article_hotness_score).and_call_original

      described_class.new.perform(article.user_id)

      expect(BlackBox).to have_received(:article_hotness_score)
      expect(article.reload.score).not_to eq(20)
    end

    it "skips draft articles" do
      article = create(:article, published: false)
      allow(BlackBox).to receive(:article_hotness_score).and_call_original

      described_class.new.perform(article.user_id)

      expect(BlackBox).not_to have_received(:article_hotness_score)
    end
  end
end
