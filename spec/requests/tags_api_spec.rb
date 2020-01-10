require "rails_helper"

RSpec.describe "ArticlesApi", type: :request do
  describe "GET /api/tags" do
    it "returns tag objects" do
      tag = create(:tag)
      get "/api/tags"
      expect(response.body).to include("bg_color_hex")
      expect(response.body).to include("[")
      expect(response.body).to include(tag.name)
    end
  end

  describe "GET /api/tags/onboarding" do
    it "returns onboarding tag objects" do
      tag = create(:tag, name: "ruby")
      get "/api/tags/onboarding"
      expect(response.body).to include("bg_color_hex")
      expect(response.body).to include("[")
      expect(response.body).to include(tag.name)
    end

    it "does not return incorrect onboarding tag objects" do
      tag = create(:tag, name: "dsdsdsdsdsdssddsdsds")
      get "/api/tags/onboarding"
      expect(response.body).not_to include(tag.name)
    end
  end
end
