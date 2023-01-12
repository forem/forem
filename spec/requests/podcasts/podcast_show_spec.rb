require "rails_helper"

RSpec.describe "PodcastShow" do
  describe "GET podcast show" do
    it "renders 404 for an unreachable podcast" do
      podcast = create(:podcast, reachable: false)
      expect do
        get "/#{podcast.slug}"
      end.to raise_error(ActiveRecord::RecordNotFound)
    end

    it "renders ok" do
      podcast = create(:podcast)
      create(:podcast_episode, podcast: podcast)
      get "/#{podcast.slug}"
      expect(response).to have_http_status(:ok)
    end

    it "shows reachable podcasts" do
      podcast = create(:podcast)
      create(:podcast_episode, title: "Bats' life", podcast: podcast)
      create(:podcast_episode, reachable: false, title: "Really old one", podcast: podcast)
      get "/#{podcast.slug}"
      expect(response.body).to include(CGI.escapeHTML("Bats' life"))
      expect(response.body).not_to include("Really old one")
    end

    it "renders 404 when podcast is unpublished" do
      unpodcast = create(:podcast, reachable: true, published: false)
      create(:podcast_episode, reachable: true)
      expect do
        get "/#{unpodcast.slug}"
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
