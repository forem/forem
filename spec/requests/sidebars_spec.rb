require "rails_helper"

RSpec.describe "Sidebars" do
  describe "GET /sidebars/home" do
    it "includes relevant parts" do
      listing = create(:listing, published: true)
      allow(Settings::General).to receive(:sidebar_tags).and_return(["rubymagoo"])
      get "/sidebars/home"
      expect(response.body).to include("rubymagoo")
      expect(response.body).to include(CGI.escapeHTML(listing.title))
    end
  end
end
