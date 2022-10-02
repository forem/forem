require "rails_helper"

RSpec.describe "Api::V1::PodcastEpisodes", type: :request do
  let(:podcast) { create(:podcast) }
  let(:headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }

  describe "GET /api/podcast_episodes" do
    it "returns json response" do
      get api_podcast_episodes_path, headers: headers

      expect(response.media_type).to eq("application/json")
    end

    it "does not return unreachable podcasts" do
      create(:podcast_episode, reachable: false, podcast: podcast)

      get api_podcast_episodes_path, headers: headers

      expect(response.parsed_body.size).to eq(0)
    end

    it "does not return reachable podcast episodes belonging to unpublished podcasts" do
      pe = create(:podcast_episode, reachable: true, podcast: create(:podcast, published: false))

      get api_podcast_episodes_path, headers: headers

      expect(response.parsed_body.map { |e| e["id"] }).not_to include(pe.id.to_s)
    end

    it "returns correct attributes for an episode", :aggregate_failures do
      podcast_episode = create(:podcast_episode, podcast: podcast)

      get api_podcast_episodes_path, headers: headers

      response_episode = response.parsed_body.first
      expect(response_episode.keys).to match_array(%w[class_name type_of id path image_url title podcast])

      expect(response_episode["type_of"]).to eq("podcast_episodes")
      expect(response_episode["class_name"]).to eq("PodcastEpisode")
      %w[id path title].each do |attr|
        expect(response_episode[attr]).to eq(podcast_episode.public_send(attr))
      end
      expect(response_episode["image_url"]).to eq(podcast_episode.podcast.image_url)
    end

    it "returns the episode's podcast json representation" do
      podcast_episode = create(:podcast_episode, podcast: podcast)

      get api_podcast_episodes_path, headers: headers

      response_episode = response.parsed_body.first
      expect(response_episode["podcast"]["title"]).to eq(podcast_episode.podcast.title)
      expect(response_episode["podcast"]["slug"]).to eq(podcast_episode.podcast.slug)
      expect(response_episode["podcast"]["image_url"]).to eq(podcast_episode.podcast.image_url)
    end

    it "returns episodes in reverse publishing order" do
      pe1 = create(:podcast_episode, published_at: 1.day.ago, podcast: podcast)
      pe2 = create(:podcast_episode, published_at: 1.day.from_now, podcast: podcast)

      get api_podcast_episodes_path, headers: headers
      expect(response.parsed_body.map { |pe| pe["id"] }).to eq([pe2.id, pe1.id])
    end

    it "supports pagination" do
      create_list(:podcast_episode, 3, podcast: podcast)

      get api_podcast_episodes_path, params: { page: 1, per_page: 2 }, headers: headers
      expect(response.parsed_body.length).to eq(2)

      get api_podcast_episodes_path, params: { page: 2, per_page: 2 }, headers: headers
      expect(response.parsed_body.length).to eq(1)
    end

    it "respects API_PER_PAGE_MAX limit set in ENV variable" do
      allow(ApplicationConfig).to receive(:[]).and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("APP_PROTOCOL").and_return("http://")
      allow(ApplicationConfig).to receive(:[]).with("API_PER_PAGE_MAX").and_return(2)

      create_list(:podcast_episode, 3, podcast: podcast)

      get api_podcast_episodes_path, params: { per_page: 10 }, headers: headers
      expect(response.parsed_body.count).to eq(2)
    end

    it "sets the correct edge caching surrogate key for all tags" do
      podcast_episode = create(:podcast_episode, reachable: true, podcast: podcast)

      get api_podcast_episodes_path, headers: headers

      expected_key = ["podcast_episodes", podcast_episode.record_key].to_set
      expect(response.headers["surrogate-key"].split.to_set).to eq(expected_key)
    end

    context "when given a username parameter" do
      it "returns only podcasts for a given username" do
        pe1 = create(:podcast_episode, podcast: podcast)
        create(:podcast_episode, podcast: create(:podcast))

        get api_podcast_episodes_path(username: podcast.slug), headers: headers
        expect(response.parsed_body.map { |pe| pe["id"] }).to eq([pe1.id])
      end

      it "returns not found if the episode belongs to an unpublished podcast" do
        unavailable_podcast = create(:podcast, published: false)
        create(:podcast_episode, podcast: unavailable_podcast)

        get api_podcast_episodes_path(username: unavailable_podcast.slug), headers: headers

        expect(response).to have_http_status(:not_found)
      end

      it "returns not found if the podcast episode is unreachable" do
        create(:podcast_episode, reachable: false, podcast: podcast)

        get api_podcast_episodes_path(username: podcast.slug), headers: headers

        expect(response).to have_http_status(:not_found)
      end

      it "returns not found if the username does not exist" do
        get api_podcast_episodes_path(username: "foobar"), headers: headers

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
