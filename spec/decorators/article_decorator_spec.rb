require "rails_helper"

RSpec.describe ArticleDecorator, type: :decorator do
  describe "published_timestamp" do
    it "returns empty string if the article is new" do
      expect(Article.new.decorate.published_timestamp).to eq("")
    end

    it "returns empty string if the article is not published" do
      article = build_stubbed(:article, published: false).decorate
      expect(article.published_timestamp).to eq("")
    end

    it "returns the timestamp of the crossposting date over the publishing date" do
      crossposted_at = 1.week.ago
      published_at = 1.day.ago
      article = build_stubbed(:article, crossposted_at: crossposted_at, published_at: published_at)
      expect(article.decorate.published_timestamp).to eq(crossposted_at.utc.iso8601)
    end

    it "returns the timestamp of the publishing date if there is no crossposting date" do
      published_at = 1.day.ago
      article = build_stubbed(:article, crossposted_at: nil, published_at: published_at).decorate
      expect(article.published_timestamp).to eq(published_at.utc.iso8601)
    end
  end
end
