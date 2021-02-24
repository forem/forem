require "rails_helper"

RSpec.describe BustCachePathWorker, type: :worker do
  let(:worker) { subject }
  let(:buster) { instance_double(EdgeCache::Buster) }

  include_examples "#enqueues_on_correct_queue", "high_priority"

  describe "#perform" do
    let(:path) { "/foo" }

    before do
      allow(EdgeCache::Buster).to receive(:new).and_return(buster)
      allow(buster).to receive(:bust).with(path)
    end

    it "busts cache for given path" do
      worker.perform(path)
      expect(buster).to have_received(:bust).with(path)
    end
  end
end
