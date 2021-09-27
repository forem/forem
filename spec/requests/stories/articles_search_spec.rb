require "rails_helper"

RSpec.describe "Stories::ArticlesSearchController", type: :request do
  describe "GET query page" do
    it "renders page with proper header" do
      get "/search?q=hello"
      expect(response.body).to include("=> Search Results")
    end

    context "with non-empty query" do
      it "renders search term in page title" do
        get "/search?q=hello"
        expect(response.body).to include("Search results for hello")
      end
    end

    context "with empty query" do
      it "renders default page title" do
        get "/search?q="
        expect(response.body).to include("Search results\s")
      end
    end
  end
end
