require "rails_helper"

RSpec.describe "Cache tasks", type: :task do
  describe "cache:enqueue_path_bust_workers" do
    let(:configured_worker) { class_double(EdgeCache::PurgeByKeyWorker, perform_in: true) }

    before do
      Rake.application["cache:enqueue_path_bust_workers"].reenable
      allow(EdgeCache::PurgeByKeyWorker).to receive(:set).with(queue: :high_priority).and_return(configured_worker)
    end

    it "schedules surrogate key purges after the Heroku Preboot window by default (240s, 420s, 600s)" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("CACHE_BUST_DELAYS_SECONDS", "240,420,600").and_return("240,420,600")

      Rake::Task["cache:enqueue_path_bust_workers"].invoke

      [240, 420, 600].each do |seconds|
        expect(configured_worker).to have_received(:perform_in).with(
          seconds.seconds,
          %w[main_app_home_page onboarding-slideshow],
          %w[/ /onboarding],
        ).once
      end
    end

    it "supports custom delays via CACHE_BUST_DELAYS_SECONDS" do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with("CACHE_BUST_DELAYS_SECONDS", "240,420,600").and_return("300, 600")

      Rake::Task["cache:enqueue_path_bust_workers"].invoke

      [300, 600].each do |seconds|
        expect(configured_worker).to have_received(:perform_in).with(
          seconds.seconds,
          %w[main_app_home_page onboarding-slideshow],
          %w[/ /onboarding],
        ).once
      end
    end
  end
end
