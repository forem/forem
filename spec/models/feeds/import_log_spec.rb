require "rails_helper"

RSpec.describe Feeds::ImportLog do
  let(:user) { create(:user) }

  before do
    allow(Feeds::ValidateUrl).to receive(:call).and_return(true)
  end

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:feed_source).optional }
    it { is_expected.to have_many(:import_items).dependent(:delete_all) }
  end

  describe "enums" do
    it {
      is_expected.to define_enum_for(:status)
        .with_values(pending: 0, fetching: 1, parsing: 2, importing: 3, completed: 4, failed: 5)
    }
  end

  describe "scopes" do
    describe ".recent" do
      it "orders by created_at desc" do
        old_log = create(:feed_import_log, user: user, created_at: 2.days.ago)
        new_log = create(:feed_import_log, user: user, created_at: 1.hour.ago)

        expect(described_class.recent).to eq([new_log, old_log])
      end
    end

    describe ".for_feed_source" do
      it "filters by feed_source_id" do
        source = create(:feed_source, user: user)
        linked = create(:feed_import_log, user: user, feed_source: source)
        unlinked = create(:feed_import_log, user: user)

        expect(described_class.for_feed_source(source.id)).to include(linked)
        expect(described_class.for_feed_source(source.id)).not_to include(unlinked)
      end
    end

    describe ".for_cleanup" do
      it "returns logs older than 30 days" do
        old_log = create(:feed_import_log, user: user, created_at: 31.days.ago)
        recent_log = create(:feed_import_log, user: user, created_at: 29.days.ago)

        expect(described_class.for_cleanup).to include(old_log)
        expect(described_class.for_cleanup).not_to include(recent_log)
      end
    end
  end

  describe "#feed_source_name" do
    it "returns source name when available" do
      source = create(:feed_source, user: user, name: "My Blog")
      log = create(:feed_import_log, user: user, feed_source: source)
      expect(log.feed_source_name).to eq("My Blog")
    end

    it "returns source feed_url when no name" do
      source = create(:feed_source, user: user, name: nil)
      log = create(:feed_import_log, user: user, feed_source: source)
      expect(log.feed_source_name).to eq(source.feed_url)
    end

    it "falls back to log feed_url when no source" do
      log = create(:feed_import_log, user: user, feed_url: "https://old.example.com/feed.xml")
      expect(log.feed_source_name).to eq("https://old.example.com/feed.xml")
    end
  end

  describe "factory" do
    it "creates a valid import log" do
      log = create(:feed_import_log, user: user)
      expect(log).to be_valid
      expect(log).to be_completed
    end

    it "creates a valid failed import log" do
      log = create(:feed_import_log, :failed, user: user)
      expect(log).to be_valid
      expect(log).to be_failed
      expect(log.error_message).to be_present
    end
  end
end
