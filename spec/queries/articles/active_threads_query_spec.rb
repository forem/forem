require "rails_helper"

RSpec.describe Articles::ActiveThreadsQuery, type: :query do
  before do
    create(:article, score: described_class::MINIMUM_SCORE - 1, tags: "watercooler")
  end

  describe "::call" do
    context "when time_ago is latest" do
      it "returns the latest article with a good score", :aggregate_failures do
        article = create(:article, tags: "discuss", score: described_class::MINIMUM_SCORE + 1)
        create(:article, published_at: 2.days.ago, tags: "discuss", score: described_class::MINIMUM_SCORE + 1)

        result = described_class.call(options: { tags: "discuss", time_ago: "latest", count: 10 })
        expect(result.length).to eq(2)
        expect(result.first.first).to eq(article.path)
      end

      it "returns any article if no higher-quality article is found", :aggregate_failures do
        article = create(:article, tags: "discuss", score: described_class::MINIMUM_SCORE - 10)

        result = described_class.call(options: { tags: "discuss", time_ago: "latest", count: 10 })
        expect(result.length).to eq(1)
        expect(result.first.first).to eq(article.path)
      end
    end

    context "when given a precise time" do
      it "returns article ordered_by comment_count based on time", :aggregate_failures do
        time = 2.days.ago
        article = create(:article, comments_count: 20, published_at: time, tags: "discuss",
                                   score: described_class::MINIMUM_SCORE)
        create(:article, comments_count: 10, tags: "discuss", score: described_class::MINIMUM_SCORE)
        create(:article, published_at: time - 2.days,  comments_count: 30, tags: "discuss",
                         score: described_class::MINIMUM_SCORE)

        result = described_class.call(tags: "discuss", time_ago: time, count: 10)
        expect(result.length).to eq(2)
        expect(result.first.first).to eq(article.path)
      end

      it "returns any article when no higher-quality article could be found", :aggregate_failures do
        time = 2.days.ago
        article = create(:article, comments_count: 20, published_at: time - 5.days, tags: "discuss",
                                   score: described_class::MINIMUM_SCORE)
        create(:article, comments_count: 10, tags: "discuss", score: described_class::MINIMUM_SCORE - 10)

        result = described_class.call(tags: "discuss", time_ago: time, count: 10)
        expect(result.length).to eq(2)
        expect(result.first.first).to eq(article.path)
      end
    end

    context "when time_ago is not given" do
      it "returns articles ordered by last_comment_at, not based on time", :aggregate_failures do
        article = create(:article, last_comment_at: Time.zone.now, tags: "discuss",
                                   score: described_class::MINIMUM_SCORE)
        create(:article, last_comment_at: nil, tags: "discuss", score: described_class::MINIMUM_SCORE)

        result = described_class.call(tags: "discuss", time_ago: nil, count: 10)
        expect(result.length).to eq(2)
        expect(result.first.first).to eq(article.path)
      end

      it "returns any article, with nil articles last, if no higher-quality articles exist", :aggregate_failures do
        article = create(:article, last_comment_at: Time.zone.now, tags: "discuss",
                                   score: described_class::MINIMUM_SCORE - 10)
        create(:article, last_comment_at: 2.days.ago, tags: "discuss", score: described_class::MINIMUM_SCORE - 10)

        result = described_class.call(tags: "discuss", time_ago: nil, count: 10)
        expect(result.length).to eq(2)
        expect(result.first.first).to eq(article.path)
      end
    end
  end
end
