require "rails_helper"

RSpec.describe Feeds::ImportItem do
  describe "associations" do
    it { is_expected.to belong_to(:import_log) }
    it { is_expected.to belong_to(:article).optional }
  end

  describe "enums" do
    it {
      is_expected.to define_enum_for(:status)
        .with_values(imported: 0, skipped_duplicate: 1, skipped_medium_reply: 2, failed: 3)
    }
  end

  describe "factory" do
    let(:user) { create(:user) }
    let(:import_log) { create(:feed_import_log, user: user) }

    it "creates a valid import item" do
      item = create(:feed_import_item, import_log: import_log)
      expect(item).to be_valid
    end

    it "creates a valid skipped import item" do
      item = create(:feed_import_item, :skipped, import_log: import_log)
      expect(item).to be_valid
      expect(item).to be_skipped_duplicate
    end

    it "creates a valid failed import item" do
      item = create(:feed_import_item, :failed, import_log: import_log)
      expect(item).to be_valid
      expect(item).to be_failed
      expect(item.error_message).to be_present
    end
  end
end
