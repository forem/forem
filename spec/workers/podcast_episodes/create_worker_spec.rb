require "rails_helper"

RSpec.describe PodcastEpisodes::CreateWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "high_priority", [123, "cache_key"]

  describe "#perform" do
    let(:worker) { subject }

    let(:podcast_id) { 781 }
    let(:cache_key) { "ep_cache_key" }

    before do
      allow(Podcasts::CreateEpisode).to receive(:call)
    end

    it "creates a podcast episode" do
      allow(Rails.cache).to receive(:read).and_return({})
      worker.perform(podcast_id, cache_key)

      expect(Podcasts::CreateEpisode).to have_received(:call).with(podcast_id, {}).once
      expect(Rails.cache).to have_received(:read).with(cache_key).once
    end

    it "does not create a podcast episode if item is not found" do
      allow(Rails.cache).to receive(:read)
      worker.perform(podcast_id, cache_key)

      expect(Podcasts::CreateEpisode).not_to have_received(:call)
    end
  end
end
