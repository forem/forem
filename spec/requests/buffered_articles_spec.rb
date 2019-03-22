require "rails_helper"

RSpec.describe "BufferedArticles", type: :request do
  describe "GET /buffered_articles" do
    it "works! (now write some real specs)" do
      get "/buffered_articles"
      expect(response).to have_http_status(:ok)
    end
    it "responds with json" do
      get "/buffered_articles"
      expect(response.content_type).to eq("application/json")
    end
    it "responds with at least one url" do
      create(:article)
      get "/buffered_articles"
      expect(response.body).to include(ApplicationConfig["APP_DOMAIN"])
    end
  end
end
