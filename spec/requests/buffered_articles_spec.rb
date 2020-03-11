require "rails_helper"

RSpec.describe "BufferedArticles", type: :request do
  describe "GET /buffered_articles" do
    it "works successfully" do
      get buffered_articles_path

      expect(response).to have_http_status(:ok)
    end

    it "responds with json" do
      get buffered_articles_path

      expect(response.content_type).to eq("application/json")
    end

    it "responds with at least one url" do
      article = create(:article)

      get buffered_articles_path
      expect(response.parsed_body["urls"].first).to eq(article.decorate.url)
    end
  end
end
