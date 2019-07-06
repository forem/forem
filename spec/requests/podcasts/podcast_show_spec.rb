require "rails_helper"

RSpec.describe "PodcastShow", type: :request do
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
  end
end
