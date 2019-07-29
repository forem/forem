require "rails_helper"

RSpec.describe "PodcastEpisodesSpec", type: :request do
  describe "GET podcast episodes index" do
    it "renders page with proper sidebar" do
      get "/pod"
      expect(response.body).to include("If you know of a great dev podcast")
    end

    it "shows reachable podcasts" do
      create(:podcast_episode, title: "SuperMario")
      create(:podcast_episode, reachable: false, title: "I'm unreachable")
      get "/pod"
      expect(response.body).to include("SuperMario")
      expect(response.body).not_to include("unreachable")
    end
  end
end
