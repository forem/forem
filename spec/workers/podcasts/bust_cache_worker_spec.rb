require "rails_helper"

RSpec.describe Podcasts::BustCacheWorker, type: :worker do
  let(:worker) { subject }
  let(:path) { "path" }

  before do
    allow(EdgeCache::BustPodcast).to receive(:call).with(path)
  end

  describe "#perform" do
    it "busts cache" do
      worker.perform(path)
      expect(EdgeCache::BustPodcast).to have_received(:call).with(path)
    end
  end
end
