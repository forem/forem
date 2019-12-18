require "rails_helper"

RSpec.describe ArticleDecorator, type: :decorator do
  let(:article) { build_stubbed(:article) }

  describe "#processed_canonical_url" do
    it "strips canonical_url" do
      article.canonical_url = " http://google.com "
      expect(article.decorate.processed_canonical_url). to eq("http://google.com")
    end

    it "returns the article url without a canonical_url" do
      article.canonical_url = ""
      expect(article.decorate.processed_canonical_url). to eq("https://#{ApplicationConfig['APP_DOMAIN']}#{article.path}")
    end
  end

  describe "#title_length_classification" do
    it "returns article title length classifications" do
      article.title = "0" * 106
      expect(article.decorate.title_length_classification).to eq("longest")
      article.title = "0" * 81
      expect(article.decorate.title_length_classification).to eq("longer")
      article.title = "0" * 61
      expect(article.decorate.title_length_classification).to eq("long")
      article.title = "0" * 23
      expect(article.decorate.title_length_classification).to eq("medium")
      article.title = "0" * 20
      expect(article.decorate.title_length_classification).to eq("short")
    end
  end
end
