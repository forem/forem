require "rails_helper"

RSpec.describe PodcastEpisodes::BustCacheJob do
  include_examples "#enqueues_job", "podcast_episodes_bust_cache", 789, "/PodCAst/SlUg", "SlUg"

  describe "#perform_now" do
    let!(:podcast) { create(:podcast) }
    let!(:podcast_episode) { FactoryBot.create(:podcast_episode, podcast_id: podcast.id) }
    let(:cache_buster) { instance_double(CacheBuster) }

    before do
      allow(CacheBuster).to receive(:new).and_return(cache_buster)
      allow(cache_buster).to receive(:bust_podcast_episode)
    end

    describe "when no podcast episode is found" do
      it "does not call the service" do
        allow(PodcastEpisode).to receive(:find_by).and_return(nil)
        described_class.perform_now(789, "/PodCAst/SlUg", "SlUg", cache_buster)
        expect(cache_buster).not_to have_received(:bust_podcast_episode)
      end
    end

    it "busts cache" do
      described_class.perform_now(podcast_episode.id, "/PodCAst/SlUg", "SlUg", cache_buster)
      expect(cache_buster).to have_received(:bust_podcast_episode).with(podcast_episode, "/PodCAst/SlUg", "SlUg")
    end
  end
end
