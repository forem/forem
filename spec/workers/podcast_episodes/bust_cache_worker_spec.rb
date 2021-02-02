require "rails_helper"

RSpec.describe PodcastEpisodes::BustCacheWorker, type: :worker do
  describe "#perform" do
    let(:worker) { subject }

    before do
      allow(EdgeCache::BustPodcastEpisode).to receive(:call)
    end

    context "when no podcast episode is found" do
      it "does not call the service" do
        worker.perform(nil, "/PodCAst/SlUg", "SlUg")
        expect(EdgeCache::BustPodcastEpisode).not_to have_received(:call)
      end
    end

    context "when a path is not provided" do
      let(:podcast) { create(:podcast) }
      let(:podcast_episode) { FactoryBot.create(:podcast_episode, podcast_id: podcast.id) }

      it "does not call the service" do
        worker.perform(podcast_episode.id, nil, "SlUg")
        expect(EdgeCache::BustPodcastEpisode).not_to have_received(:call)
      end
    end

    context "when a slug is not provided" do
      let(:podcast) { create(:podcast) }
      let(:podcast_episode) { FactoryBot.create(:podcast_episode, podcast_id: podcast.id) }

      it "does not call the service" do
        worker.perform(podcast_episode.id, "/PodCAst/SlUg", nil)
        expect(EdgeCache::BustPodcastEpisode).not_to have_received(:call)
      end
    end

    context "when podcast episode is found" do
      let(:podcast) { create(:podcast) }
      let(:podcast_episode) { FactoryBot.create(:podcast_episode, podcast_id: podcast.id) }

      it "busts cache" do
        worker.perform(podcast_episode.id, "/PodCAst/SlUg", "SlUg")
        expect(EdgeCache::BustPodcastEpisode).to have_received(:call).with(podcast_episode, "/PodCAst/SlUg", "SlUg")
      end
    end
  end
end
