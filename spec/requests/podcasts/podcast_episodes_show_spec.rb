require "rails_helper"

RSpec.describe "Podcast Episodes Show Spec", type: :request do
  describe "GET podcast episodes show" do
    it "renders the correct podcast episode" do
      podcast = create(:podcast)
      podcast_episode = create(:podcast_episode, podcast: podcast)
      get "/#{podcast.slug}/#{podcast_episode.slug}"
      expect(response.body).to include podcast_episode.title
    end

    it "does not render another podcast's episode if the wrong podcast slug is given" do
      podcast = create(:podcast)
      other_podcast = create(:podcast)
      podcast_episode = create(:podcast_episode, podcast: podcast)
      expect do
        get "/#{other_podcast.slug}/#{podcast_episode.slug}"
      end.to raise_error(ActiveRecord::RecordNotFound)
    end
  end
end
