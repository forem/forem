require "rails_helper"

RSpec.describe BustCachePathWorker, type: :worker do
  let(:worker) { subject }

  include_examples "#enqueues_on_correct_queue", "high_priority"

  describe "#perform" do
    before do
      allow(EdgeCache::PurgeByKey).to receive(:call)
      allow(EdgeCache::Bust).to receive(:call)
    end

    it "maps known global paths to EdgeCache::PurgeByKey", :aggregate_failures do
      worker.perform("/")
      worker.perform("/feed.xml")
      worker.perform("/onboarding")

      expect(EdgeCache::PurgeByKey).to have_received(:call).with("main_app_home_page", fallback_paths: "/")
      expect(EdgeCache::PurgeByKey).to have_received(:call).with("articles-feed", fallback_paths: "/feed.xml")
      expect(EdgeCache::PurgeByKey).to have_received(:call).with("onboarding-slideshow", fallback_paths: "/onboarding")
      expect(EdgeCache::Bust).not_to have_received(:call)
    end

    it "falls back to EdgeCache::Bust for unmapped paths" do
      worker.perform("/foo")

      expect(EdgeCache::Bust).to have_received(:call).with("/foo")
      expect(EdgeCache::PurgeByKey).not_to have_received(:call)
    end
  end
end
