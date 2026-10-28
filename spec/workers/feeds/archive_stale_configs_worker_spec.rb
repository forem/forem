require "rails_helper"

RSpec.describe Feeds::ArchiveStaleConfigsWorker, type: :worker do
  describe "#perform" do
    it "delegates to FeedConfig.archive_stale_configs!" do
      allow(FeedConfig).to receive(:archive_stale_configs!)
      described_class.new.perform
      expect(FeedConfig).to have_received(:archive_stale_configs!)
    end
  end
end
