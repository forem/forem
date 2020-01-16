require "rails_helper"

RSpec.describe Metrics::RecordDailyUsageWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "low_priority", 1
  let_it_be(:first_user) { create(:user, comments_count: 1) }
  let_it_be(:second_user) { create(:user, comments_count: 2) }
  let_it_be(:third_user) { create(:user, comments_count: 0) }
  let_it_be(:first_article) { create(:article, score: 15, nth_published_by_author: 1) }
  let_it_be(:second_article) { create(:article, score: 5, nth_published_by_author: 2) }
  let_it_be(:third_article) { create(:article, score: 38, nth_published_by_author: 3) }

  describe "#perform" do
    before do
      allow(DataDogStatsClient).to receive(:count)
      described_class.new.perform
    end

    it "logs articles with at least 15 score" do
      expect(
        DataDogStatsClient,
      ).to have_received(:count).with("articles.min_15_score_past_24h", 2, Hash).at_least(1)
    end

    it "records first articles" do
      expect(
        DataDogStatsClient,
      ).to have_received(:count).with("articles.first_past_24h", 1, Hash).at_least(1)
    end

    it "records new users with at least one comment" do
      expect(
        DataDogStatsClient,
      ).to have_received(:count).with("users.new_min_1_comment_past_24h", 2, Hash).at_least(1)
    end
  end
end
