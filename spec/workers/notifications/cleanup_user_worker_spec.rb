require "rails_helper"

RSpec.describe Notifications::CleanupUserWorker, type: :worker do
  describe "#perform" do
    it "calls Notification.fast_cleanup_older_than_100_for with the provided user_id" do
      allow(Notification).to receive(:fast_cleanup_older_than_100_for)

      described_class.new.perform(123)

      expect(Notification).to have_received(:fast_cleanup_older_than_100_for).with(123)
    end
  end
end
