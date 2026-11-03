require "rails_helper"

RSpec.describe Articles::ApiSearchQuery, type: :query do
  before do
    create(:article, published: false)
    create(:article, title: "Top ten Interview tips")
    create(:article, title: "Top ten Ruby tips")
    create(:article, title: "Frontend Frameworks")
    create(:article)
  end

  context "when there is no query parameter" do
    it "shows all published and approved articles" do
      articles = described_class.call({})
      # The one not included has publiched set to false.
      expect(articles.count).to eq(4)
    end
  end

  context "when there is a query parameter" do
    it "shows articles that match that query" do
      articles = described_class.call({ q: "ruby" })
      expect(articles.count).to eq(1)
    end

    it "does not show article if below minimum index" do
      Settings::UserExperience.index_minimum_score = 10_000
      articles = described_class.call({ q: "ruby" })
      expect(articles.count).to eq(0)
      Settings::UserExperience.index_minimum_score = 0
    end

    it "orders matching articles by hotness_score expression without computing ts_rank or walking the B-tree index",
       :aggregate_failures do
      low_hotness = Article.find_by(title: "Top ten Interview tips")
      high_hotness = Article.find_by(title: "Top ten Ruby tips")
      low_hotness.update_columns(hotness_score: 10)
      high_hotness.update_columns(hotness_score: 100)

      relation = described_class.call({ q: "tips" })
      sql = relation.to_sql

      expect(relation.map(&:id)).to eq([high_hotness.id, low_hotness.id])
      expect(sql).to include("(articles.score + 0) >=")
      expect(sql).to include("(articles.hotness_score + 0) DESC")
      expect(sql).not_to include("ts_rank")
      expect(sql).not_to include("INNER JOIN")
    end

    it "orders by score expression and wraps published_at when both q and top parameters are present",
       :aggregate_failures do
      low_score = Article.find_by(title: "Top ten Interview tips")
      high_score = Article.find_by(title: "Top ten Ruby tips")
      low_score.update_columns(score: 5, hotness_score: 500)
      high_score.update_columns(score: 50, hotness_score: 5)

      relation = described_class.call({ q: "tips", top: 7 })
      sql = relation.to_sql

      expect(relation.map(&:id)).to eq([high_score.id, low_score.id])
      expect(sql).to include("(articles.published_at + INTERVAL '0 seconds') >")
      expect(sql).to include("(articles.score + 0) >=")
      expect(sql).to include("(articles.score + 0) DESC")
      expect(sql).not_to include("ts_rank")
    end

    it "falls back to DEFAULT_PER_PAGE when per_page is blank or non-positive" do
      relation = described_class.call({ q: "tips", per_page: "" })
      expect(relation.limit_value).to eq(described_class::DEFAULT_PER_PAGE)
    end
  end

  context "when there is a top parameter" do
    it "shows the most popular articles in the last n days" do
      article = Article.find_by(title: "Frontend Frameworks")
      article.update_column(:published_at, 30.days.ago)

      # The two not included is the one that has publiched set to false.
      articles = described_class.call({ top: 10 })
      expect(articles.count).to eq(3)
    end
  end
end
