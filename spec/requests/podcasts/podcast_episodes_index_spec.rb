require "rails_helper"

RSpec.describe "PodcastEpisodesSpec", type: :request do
  describe "GET podcast episodes index" do
    xit "renders page with proper sidebar" do
      get "/pod"
      expect(response.body).to include("Suggest a Podcast")
    end

    xit "shows reachable podcasts" do
      create(:podcast_episode, title: "SuperMario")
      create(:podcast_episode, reachable: false, title: "I'm unreachable")
      get "/pod"
      expect(response.body).to include("SuperMario")
      expect(response.body).not_to include("unreachable")
    end

    xit "sets proper surrogate key" do
      pe = create(:podcast_episode)
      get "/pod"
      expect(response.headers["Surrogate-Key"]).to eq("podcast_episodes_all podcast_episodes/#{pe.id}")
    end

    xit "redirects /podcasts to /pod" do
      get "/podcasts"
      expect(response.body).to redirect_to(pod_path)
    end
  end
end
