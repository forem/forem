require "rails_helper"

RSpec.describe BustCachePathWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "high_priority"

  describe "#perform" do
    let(:path) { "/foo" }

    it "busts cache for given path" do
      allow(EdgeCache::Bust).to receive(:call).with(path)
      worker.perform(path)
      expect(EdgeCache::Bust).to have_received(:call).with(path)
    end
  end
end
