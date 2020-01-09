require "rails_helper"

RSpec.describe Podcasts::BustCacheWorker, type: :worker do
  let(:worker) { subject }

  before do
    allow(CacheBuster).to receive(:bust_podcast)
  end

  describe "#perform" do
    it "busts cache" do
      worker.perform("path")
      expect(CacheBuster).to have_received(:bust_podcast).with("path")
    end
  end
end
