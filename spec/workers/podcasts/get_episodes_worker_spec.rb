require "rails_helper"

RSpec.describe Podcasts::GetEpisodesWorker, type: :worker do
  describe "#perform" do
    let(:podcast) { create(:podcast) }
    let(:feed) { instance_double(Podcasts::Feed) }
    let(:worker) { subject }

    before do
      allow(Podcasts::Feed).to receive(:new).and_return(feed)
      allow(feed).to receive(:get_episodes)
    end

    it "calls the service" do
      worker.perform(podcast_id: podcast.id, limit: 5, force_update: true)
      expect(feed).to have_received(:get_episodes)
    end

    it "doesn't call the service when the podcast is not found" do
      worker.perform(podcast_id: Podcast.maximum(:id).to_i + 1, limit: 5)
      expect(feed).not_to have_received(:get_episodes)
    end
  end
end
