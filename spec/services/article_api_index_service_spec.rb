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

  describe "#get with no filters" do
    it "returns only featured articles ordered by hotness_score" do
      featured_low = create(:article, featured: true, hotness_score: 10)
      featured_high = create(:article, featured: true, hotness_score: 50)
      create(:article, featured: false, hotness_score: 100)

      expect(described_class.new({}).get.to_a).to eq([featured_high, featured_low])
    end

    it "has a partial hotness_score index for featured articles" do
      index = ActiveRecord::Base.connection.indexes(:articles)
        .find { |i| i.name == "index_articles_on_hotness_score_where_featured" }

      expect(index).to have_attributes(columns: ["hotness_score"], where: "(featured = true)")
    end
  end
end
