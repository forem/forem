require "rails_helper"

vcr_option = {
  cassette_name: "twitter_gem",
  allow_playback_repeats: "true"
}

RSpec.describe "LiquidEmbeds", type: :request, vcr: vcr_option do
  describe "get /embeds" do
    it "renders proper tweet" do
      get "/embed/tweet?args=1018911886862057472"
      expect(response.body).to include("ltag__twitter-tweet")
    end
    it "renders 404 if improper tweet" do
      expect do
        get "/embed/tweet?args=improper"
      end.to raise_error(ActionView::Template::Error)
    end
  end
end
