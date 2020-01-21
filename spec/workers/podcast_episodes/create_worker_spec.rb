require "rails_helper"

RSpec.describe PodcastEpisodes::CreateWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "high_priority", 1

  describe "#perform" do
    let(:worker) { subject }

    let(:podcast_id) { 781 }
    let(:item) { double(:item) }

    before do
      allow(Podcasts::CreateEpisode).to receive(:call)
    end

    it "creates a podcast episode" do
      worker.perform(podcast_id, item)

      expect(Podcasts::CreateEpisode).to have_received(:call).with(podcast_id, item).once
    end
  end
end
