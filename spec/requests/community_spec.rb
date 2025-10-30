require "rails_helper"

RSpec.describe "Community", :proper_status do
  describe "GET /community" do
    it "returns proper page" do
      get community_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Community Hub")
    end

    it "displays tags section" do
      create(:tag, name: "ruby", hotness_score: 100)
      create(:tag, name: "javascript", hotness_score: 90)

      get community_path
      expect(response.body).to include("js-tag-card")
      expect(response.body).to include("ruby")
      expect(response.body).to include("javascript")
    end

    it "displays top authors section" do
      get community_path
      expect(response.body).to include("No recent authors to display")
    end

    it "displays key pages when they exist" do
      page = create(:page, title: "About Us", slug: "about", is_top_level_path: true)

      get community_path
      expect(response.body).to include("Key Resources", "About Us")
    end

    it "displays community info sidebar" do
      get community_path
      expect(response.body).to include("About")
    end
  end
end
