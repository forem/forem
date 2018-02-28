require "rails_helper"

vcr_option = {
  cassette_name: "ga_event",
  allow_playback_repeats: "true",
}

RSpec.describe "GaEvents", type: :request, vcr: vcr_option do
  describe "POST /cromulent" do
    it "posts to cromulent" do
      post "/cromulent", params: {
        path: "/ben", user_language: "en"
      }.to_json
      expect(response.body).to eq("")
    end
  end
end
