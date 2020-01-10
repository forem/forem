require "rails_helper"

RSpec.describe Podcasts::BustCacheJob do
  let(:cache_buster) { class_double(CacheBuster) }

  before do
    allow(cache_buster).to receive(:bust_podcast)
  end

  include_examples "#enqueues_job", "podcasts_bust_cache"

  describe "#perform_now" do
    it "busts cache" do
      described_class.perform_now("path", cache_buster)
      expect(cache_buster).to have_received(:bust_podcast).with("path")
    end
  end
end
