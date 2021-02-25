require "rails_helper"

RSpec.describe BustCachePathWorker, type: :worker do
  let(:worker) { subject }
  let(:cache_bust) { instance_double(EdgeCache::Bust) }

  include_examples "#enqueues_on_correct_queue", "high_priority"

  describe "#perform" do
    let(:path) { "/foo" }

    before do
      allow(EdgeCache::Bust).to receive(:new).and_return(cache_bust)
      allow(cache_bust).to receive(:call).with(path)
    end

    it "busts cache for given path" do
      worker.perform(path)
      expect(cache_bust).to have_received(:call).with(path)
    end
  end
end
