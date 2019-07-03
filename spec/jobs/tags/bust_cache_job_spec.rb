require "rails_helper"

RSpec.describe Tags::BustCacheJob do
  let(:cache_buster) { instance_double(CacheBuster) }

  before do
    allow(CacheBuster).to receive(:new).and_return(cache_buster)
    allow(cache_buster).to receive(:bust_tag)
  end

  include_examples "#enqueues_job", "tags_bust_cache", "PHP"

  describe "#perform_now" do
    it "busts cache" do
      described_class.perform_now("PHP", cache_buster)
      expect(cache_buster).to have_received(:bust_tag).with("PHP")
    end
  end
end
