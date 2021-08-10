require "rails_helper"

RSpec.describe "Stories::ArticlesSearchController", type: :request do
  describe "GET query page" do
    it "renders page with proper header" do
      get "/search?q=hello"
      expect(response.body).to include("=> Search Results")
    end
  end
end
