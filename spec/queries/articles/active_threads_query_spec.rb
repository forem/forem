require "rails_helper"

RSpec.describe Articles::ActiveThreadsQuery, type: :query do
  # let(:user) { create(:user) }
  let!(:completely_unrelated_article) do
    create(:article, score: described_class::MINIMUM_SCORE - 1, tags: "watercooler")
  end
  # let!(:unfiltered_article) do
  #   create(:article, user: user, score: -25, tags: "discuss")
  # end
  #

  describe "::call" do
    context "when time_ago is latest" do
      it "returns latest article with good score" do
        article = create(:article, tags: "discuss", score: described_class::MINIMUM_SCORE + 1)
        create(:article, published_at: 2.days.ago, tags: "discuss", score: described_class::MINIMUM_SCORE + 1)

        result = described_class.call(options: { tags: "discuss", time_ago: "latest", count: 10 })
        expect(result.length).to eq(2)
        expect(result.first.first).to eq(article.path)
      end

      it "returns any article if no good article is found" do
        article = create(:article, tags: "discuss", score: described_class::MINIMUM_SCORE - 10)

        result = described_class.call(options: { tags: "discuss", time_ago: "latest", count: 10 })
        expect(result.length).to eq(1)
        expect(result.first.first).to eq(article.path)
      end
    end

    context "when given a precise time" do
      it "returns article ordered_by comment ocunt based on time" do
        time = 2.days.ago
        article = create(:article, comments_count: 20, published_at: time, tags: "discuss",
                                   score: described_class::MINIMUM_SCORE)
        create(:article, comments_count: 10, tags: "discuss", score: described_class::MINIMUM_SCORE)
        create(:article, published_at: time - 2.days,  comments_count: 30, tags: "discuss",
                         score: described_class::MINIMUM_SCORE)

        result = described_class.call(options: { tags: "discuss", time_ago: time, count: 10 })
        expect(result.length).to eq(2)
        expect(result.first.first).to eq(article.path)
      end

      it "returns anything when couldn't find quality article" do
        time = 2.days.ago
        article = create(:article, comments_count: 20, published_at: time - 5.days, tags: "discuss",
                                   score: described_class::MINIMUM_SCORE)
        create(:article, comments_count: 10, tags: "discuss", score: described_class::MINIMUM_SCORE - 10)

        result = described_class.call(options: { tags: "discuss", time_ago: time, count: 10 })
        expect(result.length).to eq(2)
        expect(result.first.first).to eq(article.path)
      end
    end

    context "when time_ago is not given" do
      it "returns article with no ac" do
        article = create(:article, last_comment_at: Time.zone.now, tags: "discuss",
                                   score: described_class::MINIMUM_SCORE)
        create(:article, last_comment_at: nil, tags: "discuss", score: described_class::MINIMUM_SCORE)

        result = described_class.call(options: { tags: "discuss", time_ago: nil, count: 10 })
        expect(result.length).to eq(2)
        expect(result.first.first).to eq(article.path)
      end

      it "returns any article if " do
        article = create(:article, last_comment_at: Time.zone.now, tags: "discuss",
                                   score: described_class::MINIMUM_SCORE - 10)
        create(:article, last_comment_at: 2.days.ago, tags: "discuss", score: described_class::MINIMUM_SCORE - 10)

        result = described_class.call(options: { tags: "discuss", time_ago: nil, count: 10 })
        expect(result.length).to eq(2)
        expect(result.first.first).to eq(article.path)
      end
    end
  end

  # describe ".call" do
  #   context "when the articles fall within the constraints" do
  #     it "returns the latest published article falls within the score constraints" do
  #       articles = described_class.call(options: { tags: "discuss", time_ago: "latest", count: 10 })
  #       expect(articles.flatten).to include(filtered_article.path)
  #     end
  #
  #     it "returns the published article falls within the time_ago and score constraints" do
  #       articles = described_class.call(options: { tags: "discuss", time_ago: 1.hour.ago, count: 10 })
  #       expect(articles.flatten).to include(filtered_article.path)
  #     end
  #
  #     it "returns the published article falls within the published_at and score constraints" do
  #       articles = described_class.call(options: { tags: "discuss", time_ago: 6.days.ago, count: 10 })
  #       expect(articles.flatten).to include(filtered_article.path)
  #     end
  #   end
  #
  #   context "when the published article does not fall within the constraints" do
  #     it "returns the published article with the corresponding tag" do
  #       articles = described_class.call(options: { tags: "discuss", time_ago: nil, count: 10 })
  #       expect(articles.flatten).to include(unfiltered_article.path)
  #     end
  #   end
  # end
end
