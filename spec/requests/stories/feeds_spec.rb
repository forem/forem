require "rails_helper"

RSpec.describe "Stories::FeedsIndex", type: :request do
  let!(:article) { create(:article, featured: true) }

  describe "GET feeds index" do
    it "renders article list as json" do
      get "/stories/feed", headers: headers
      expect(response.content_type).to eq("application/json")
      expect(response.body).to include(article.title)
    end
  end
end
