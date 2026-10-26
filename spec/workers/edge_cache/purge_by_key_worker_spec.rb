require "rails_helper"

RSpec.describe EdgeCache::PurgeByKeyWorker, type: :worker do
  include_examples "#enqueues_on_correct_queue", "high_priority", [["users/1"], ["/user"]]

  describe "#perform" do
    before { allow(EdgeCache::PurgeByKey).to receive(:call) }

    it "purges the given keys with their fallback paths" do
      described_class.new.perform(%w[users/1 comments/2], %w[/user /user/comment/abc])

      expect(EdgeCache::PurgeByKey).to have_received(:call)
        .with(%w[users/1 comments/2], fallback_paths: %w[/user /user/comment/abc])
    end

    it "purges the given keys without fallback paths" do
      described_class.new.perform(["main_app_home_page"])

      expect(EdgeCache::PurgeByKey).to have_received(:call).with(["main_app_home_page"], fallback_paths: nil)
    end
  end
end
