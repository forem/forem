require "rails_helper"

RSpec.describe Events::BustCacheJob do
  let(:cache_buster) { instance_double(CacheBuster) }

  before do
    allow(CacheBuster).to receive(:new).and_return(cache_buster)
    allow(cache_buster).to receive(:bust_events)
  end

  include_examples "#enqueues_job", "events_bust_cache"

  describe "#perform_now" do
    it "busts cache" do
      cache_buster = double
      allow(cache_buster).to receive(:bust_events)

      described_class.perform_now(cache_buster)
      expect(cache_buster).to have_received(:bust_events)
    end
  end
end
