require "rails_helper"

RSpec.describe "Sidebars", type: :request do
  describe "GET /sidebars/home" do
    it "includes surrogate headers" do
      get "/sidebars/home"
      expect(response.headers["Surrogate-Key"]).to eq("home-sidebar")
    end

    it "includes relevant parts" do
      listing = create(:listing, published: true)
      allow(Settings::General).to receive(:sidebar_tags).and_return(["rubymagoo"])
      get "/sidebars/home"
      expect(response.body).to include("rubymagoo")
      expect(response.body).to include(CGI.escapeHTML(listing.title))
    end
  end
end
