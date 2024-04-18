require "rails_helper"

RSpec.describe "LiquidEmbeds", vcr: { cassette_name: "twitter_client_status_extended" } do
  describe "get /embeds" do
    let(:path) { liquid_embed_path("tweet", args: 1_018_911_886_862_057_472) }

    it "renders 404 if improper tweet" do
      expect do
        get liquid_embed_path("tweet", args: "improper")
      end.to raise_error(ActionController::RoutingError)
    end

    it "contains base target parent" do
      get path
      expect(response.body).to include('<base target="_parent">')
    end
  end
end
