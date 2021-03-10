require "rails_helper"

RSpec.describe Articles::ActiveThreadsQuery, type: :query do
  let(:user) { create(:user) }
  let!(:filtered_article) do
    create(:article, user: user, score: -2, tags: "discuss, watercooler")
  end
  let!(:unfiltered_article) do
    create(:article, user: user, score: -25, tags: "discuss")
  end

  describe ".call" do
    context "when the articles fall within the constraints" do
      it "returns the latest published article falls within the score constraints" do
        articles = described_class.call(options: { tags: "discuss", time_ago: "latest", count: 10 })
        expect(articles.flatten).to include(filtered_article.path)
      end

      it "returns the published article falls within the time_ago and score constraints" do
        articles = described_class.call(options: { tags: "discuss", time_ago: 1.hour.ago, count: 10 })
        expect(articles.flatten).to include(filtered_article.path)
      end

      it "returns the published article falls within the published_at and score constraints" do
        articles = described_class.call(options: { tags: "discuss", time_ago: 6.days.ago, count: 10 })
        expect(articles.flatten).to include(filtered_article.path)
      end
    end

    context "when the published article does not fall within the constraints" do
      it "returns the published article with the corresponding tag" do
        articles = described_class.call(options: { tags: "discuss", time_ago: nil, count: 10 })
        expect(articles.flatten).to include(unfiltered_article.path)
      end
    end
  end
end
