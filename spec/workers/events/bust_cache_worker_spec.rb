require "rails_helper"

RSpec.describe Events::BustCacheWorker do
  include_examples "#enqueues_on_correct_queue", "low_priority"

  describe "#perform" do
    it "busts cache" do
      allow(CacheBuster).to receive(:bust_events)
      described_class.new.perform
      expect(CacheBuster).to have_received(:bust_events)
    end
  end
end
