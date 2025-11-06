require "rails_helper"

RSpec.describe Articles::ActiveThreadsQuery, type: :query do
  let(:min_score) { Settings::UserExperience.home_feed_minimum_score }

  before do
    create(:article, score: min_score - 1, tags: "watercooler")
  end

  describe "::call" do
    context "when time_ago is latest" do
      it "returns the latest article with a good score", :aggregate_failures do
        article = create(:article, tags: "discuss", score: min_score + 1)
        create(:article, :past, past_published_at: 2.days.ago, tags: "discuss",
                                score: min_score + 1)

        result = described_class.call(tags: "discuss", time_ago: "latest", count: 10)
        expect(result.length).to eq(2)
        expect(result.first.first).to eq(article.path)
      end

      it "does not return articles below the minimum score threshold", :aggregate_failures do
        create(:article, tags: "discuss", score: min_score - 10)
        create(:article, tags: "discuss", score: min_score - 1)

        result = described_class.call(tags: "discuss", time_ago: "latest", count: 10)
        expect(result.length).to eq(0)
      end

      it "returns only articles at or above the minimum score", :aggregate_failures do
        good_article = create(:article, tags: "discuss", score: min_score)
        create(:article, tags: "discuss", score: min_score - 1)

        result = described_class.call(tags: "discuss", time_ago: "latest", count: 10)
        expect(result.length).to eq(1)
        expect(result.first.first).to eq(good_article.path)
      end
    end

    context "when given a precise time" do
      it "returns article ordered_by comment_count based on time", :aggregate_failures do
        time = 2.days.ago
        article = create(:article, :past, comments_count: 20, past_published_at: time, tags: "discuss",
                                          score: min_score)
        create(:article, comments_count: 10, tags: "discuss", score: min_score)
        create(:article, :past, past_published_at: time - 2.days, comments_count: 30, tags: "discuss",
                                score: min_score)

        result = described_class.call(tags: "discuss", time_ago: time, count: 10)
        expect(result.length).to eq(2)
        expect(result.first.first).to eq(article.path)
      end

      it "excludes articles below minimum score even with high comment counts", :aggregate_failures do
        time = 2.days.ago
        good_article = create(:article, :past, comments_count: 5, past_published_at: time, tags: "discuss",
                                               score: min_score)
        create(:article, comments_count: 100, tags: "discuss", score: min_score - 10)

        result = described_class.call(tags: "discuss", time_ago: time, count: 10)
        expect(result.length).to eq(1)
        expect(result.first.first).to eq(good_article.path)
      end

      it "respects both time and score filters", :aggregate_failures do
        time = 2.days.ago
        # Article before the time threshold
        create(:article, :past, comments_count: 20, past_published_at: time - 1.day, tags: "discuss",
                                score: min_score + 10)
        # Article after time threshold but below score threshold
        create(:article, :past, comments_count: 10, past_published_at: time + 1.hour, tags: "discuss",
                                score: min_score - 1)

        result = described_class.call(tags: "discuss", time_ago: time, count: 10)
        expect(result.length).to eq(0)
      end
    end

    context "when time_ago is not given" do
      it "returns articles ordered by last_comment_at, not based on time", :aggregate_failures do
        article = create(:article, last_comment_at: Time.zone.now, tags: "discuss",
                                   score: min_score)
        create(:article, last_comment_at: nil, tags: "discuss", score: min_score)

        result = described_class.call(tags: "discuss", time_ago: nil, count: 10)
        expect(result.length).to eq(2)
        expect(result.first.first).to eq(article.path)
      end

      it "excludes articles below minimum score regardless of last_comment_at", :aggregate_failures do
        good_article = create(:article, last_comment_at: 2.days.ago, tags: "discuss",
                                         score: min_score)
        create(:article, last_comment_at: Time.zone.now, tags: "discuss", score: min_score - 10)
        create(:article, last_comment_at: 1.day.ago, tags: "discuss", score: min_score - 1)

        result = described_class.call(tags: "discuss", time_ago: nil, count: 10)
        expect(result.length).to eq(1)
        expect(result.first.first).to eq(good_article.path)
      end

      it "respects published_at threshold of 3 days when time_ago is nil", :aggregate_failures do
        # Article published 2 days ago (within threshold)
        recent_article = create(:article, :past, past_published_at: 2.days.ago, 
                                          last_comment_at: 1.day.ago, tags: "discuss",
                                          score: min_score)
        # Article published 4 days ago (outside threshold)
        create(:article, :past, past_published_at: 4.days.ago,
                               last_comment_at: Time.zone.now, tags: "discuss",
                               score: min_score + 10)

        result = described_class.call(tags: "discuss", time_ago: nil, count: 10)
        expect(result.length).to eq(1)
        expect(result.first.first).to eq(recent_article.path)
      end
    end
  end
end
