require "rails_helper"

RSpec.describe PodcastEpisodes::BustCacheWorker, type: :worker do
  describe "#perform" do
    let!(:podcast) { create(:podcast) }
    let!(:podcast_episode) { FactoryBot.create(:podcast_episode, podcast_id: podcast.id) }
    let(:worker) { subject }

    before do
      allow(CacheBuster).to receive(:bust_podcast_episode)
    end

    describe "when no podcast episode is found" do
      it "does not call the service" do
        allow(PodcastEpisode).to receive(:find_by).and_return(nil)
        worker.perform(789, "/PodCAst/SlUg", "SlUg")
        expect(CacheBuster).not_to have_received(:bust_podcast_episode)
      end
    end

    it "busts cache" do
      worker.perform(podcast_episode.id, "/PodCAst/SlUg", "SlUg")
      expect(CacheBuster).to have_received(:bust_podcast_episode).with(podcast_episode, "/PodCAst/SlUg", "SlUg")
    end
  end
end
