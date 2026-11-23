require "rails_helper"

RSpec.describe ArticleApiIndexService do
  describe "#get with a username" do
    let(:user) { create(:user) }

    it "uses the default page size" do
      relation = described_class.new(username: user.username).get

      expect(relation.limit_value).to eq(described_class::DEFAULT_PER_PAGE)
    end

    it "raises the page size to the API maximum when state=all is requested" do
      relation = described_class.new(username: user.username, state: "all").get

      expect(relation.limit_value).to be > described_class::DEFAULT_PER_PAGE
      expect(relation.limit_value).to eq(1000)
    end

    it "honors an explicit per_page when state=all is requested" do
      relation = described_class.new(username: user.username, state: "all", per_page: 10).get

      expect(relation.limit_value).to eq(10)
    end
  end

  describe "#get default base_articles" do
    it "orders published featured articles by hotness_score descending with a matching partial index" do
      relation = described_class.new({}).get
      index = ActiveRecord::Base.connection.indexes(:articles).detect do |idx|
        idx.name == "index_articles_on_hotness_score_for_featured_published"
      end

      expect(relation.where_values_hash).to include("published" => true, "featured" => true)
      expect(index).to have_attributes(columns: ["hotness_score"], orders: :desc,
                                       where: "((published = true) AND (featured = true))")
    end
  end

  describe "#get with a tag" do
    let(:tag_name) { "ruby" }

    it "returns only published past articles for the tag ordered by hotness_score descending" do
      older_hot = create(:article, :past, tags: tag_name, past_published_at: 2.days.ago)
      newer_cold = create(:article, :past, tags: tag_name, past_published_at: 1.day.ago)
      older_hot.update_column(:hotness_score, 500)
      newer_cold.update_column(:hotness_score, 100)

      unpublished = create(:article, tags: tag_name, published: false)
      future_scheduled = create(:article, tags: tag_name, published: true, published_at: 1.day.from_now)
      other_tag = create(:article, :past, tags: "elixir", past_published_at: 1.hour.ago)

      relation = described_class.new(tag: tag_name).get

      expect(relation.to_sql).to include("COALESCE(articles.published AND articles.published_at <=")
      expect(relation.to_a).to eq([older_hot, newer_cold])
      expect(relation.to_a).not_to include(unpublished, future_scheduled, other_tag)
    end

    it "clamps top to MAX_TOP_DAYS when combined with a tag", :aggregate_failures do
      within_window = create(:article, :past, tags: tag_name, past_published_at: 700.days.ago)
      outside_window = create(:article, :past, tags: tag_name, past_published_at: 800.days.ago)

      results = described_class.new(tag: tag_name, top: 1500).get.to_a

      expect(results).to include(within_window)
      expect(results).not_to include(outside_window)
    end
  end

  describe "#get with top" do
    it "clamps top to MAX_TOP_DAYS", :aggregate_failures do
      within_window = create(:article, :past, past_published_at: 700.days.ago)
      outside_window = create(:article, :past, past_published_at: 800.days.ago)

      results = described_class.new(top: 1500).get.to_a

      expect(results).to include(within_window)
      expect(results).not_to include(outside_window)
    end

    it "clamps extreme positive and negative top values without raising", :aggregate_failures do
      within_window = create(:article, :past, past_published_at: 10.days.ago)

      expect(described_class.new(top: 999_999_999).get.to_a).to include(within_window)
      expect(described_class.new(top: -999_999_999).get.to_a).to be_empty
    end
  end
end
