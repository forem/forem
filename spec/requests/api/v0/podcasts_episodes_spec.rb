require "rails_helper"

RSpec.describe "Api::V0::PodcastEpisodes", type: :request do
  let(:podcast) { create(:podcast) }

  describe "GET /api/podcast_episodes" do
    it "returns json response" do
      get "/api/podcast_episodes"
      expect(response.content_type).to eq("application/json")
    end

    it "returns correct attributes for an episode" do
      create(:podcast_episode)
      get "/api/podcast_episodes"
      expected_attributes = %w[type_of id path image_url title podcast]
      expect(JSON.parse(response.body).first.keys).to eq(expected_attributes)
    end

    it "returns episodes in reverse publishing order" do
      pe1 = create(:podcast_episode, published_at: 1.day.ago)
      pe2 = create(:podcast_episode, published_at: 1.day.from_now)
      get "/api/podcast_episodes"
      expect(JSON.parse(response.body).map { |pe| pe["id"] }).to eq([pe2.id, pe1.id])
    end

    it "returns only podcasts for a given username" do
      pe1 = create(:podcast_episode, podcast: podcast)
      create(:podcast_episode, podcast: create(:podcast))
      get "/api/podcast_episodes?username=#{podcast.slug}"
      expect(JSON.parse(response.body).map { |pe| pe["id"] }).to eq([pe1.id])
    end

    it "returns not found if the username does not exist" do
      get "/api/podcast_episodes?username=foobar"
      expect(response).to have_http_status(:not_found)
    end
  end
end
