require "rails_helper"

RSpec.describe Feeds::ImportLogCleanupWorker, type: :worker do
  let(:user) { create(:user) }

  describe "#perform" do
    it "deletes logs older than 90 days" do
      old_log = create(:feed_import_log, user: user, created_at: 91.days.ago)
      recent_log = create(:feed_import_log, user: user, created_at: 10.days.ago)

      described_class.new.perform

      expect(Feeds::ImportLog.exists?(old_log.id)).to be(false)
      expect(Feeds::ImportLog.exists?(recent_log.id)).to be(true)
    end

    it "cascade deletes associated import items" do
      old_log = create(:feed_import_log, user: user, created_at: 91.days.ago)
      item = create(:feed_import_item, import_log: old_log)

      described_class.new.perform

      expect(Feeds::ImportItem.exists?(item.id)).to be(false)
    end

    it "does nothing when there are no old logs" do
      create(:feed_import_log, user: user, created_at: 10.days.ago)

      expect { described_class.new.perform }.not_to change(Feeds::ImportLog, :count)
    end
  end
end
