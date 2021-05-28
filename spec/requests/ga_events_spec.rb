require "rails_helper"

vcr_option = {
  cassette_name: "ga_event",
  allow_playback_repeats: "true"
}

RSpec.describe "GaEvents", type: :request, vcr: vcr_option do
  describe "POST /fallback_activity_recorder" do
    it "posts to fallback_activity_recorder" do
      post "/fallback_activity_recorder", params: {
        path: "/ben", user_language: "en"
      }.to_json
      expect(response.body).to eq("")
    end

    it "renders normal response even if the Forem instance is private" do
      allow(Settings::UserExperience).to receive(:public).and_return(false)
      post "/fallback_activity_recorder", params: {
        path: "/ben", user_language: "en"
      }.to_json
      expect(response.body).to eq("")
    end
  end
end
