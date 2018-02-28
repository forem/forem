require "rails_helper"

RSpec.describe "PodcastEpisodesSpec", type: :request do
  describe "GET podcast episodes index" do
    it "renders page with proper sidebar" do
      get "/pod"
      expect(response.body).to include("<h1>Podcasts</h1>")
    end
  end
end
