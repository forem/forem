require "rails_helper"

RSpec.describe RssFeedItem do
  describe "associations" do
    it { is_expected.to belong_to(:rss_feed) }
    it { is_expected.to belong_to(:article).optional }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:item_url) }

    it "validates uniqueness of item_url scoped to rss_feed" do
      feed = create(:rss_feed)
      create(:rss_feed_item, rss_feed: feed, item_url: "https://example.com/post-1")
      item = build(:rss_feed_item, rss_feed: feed, item_url: "https://example.com/post-1")
      expect(item).not_to be_valid
      expect(item.errors[:item_url]).to be_present
    end

    it "allows same item_url across different feeds" do
      feed1 = create(:rss_feed)
      feed2 = create(:rss_feed, user: create(:user))
      create(:rss_feed_item, rss_feed: feed1, item_url: "https://example.com/post-1")
      item = build(:rss_feed_item, rss_feed: feed2, item_url: "https://example.com/post-1")
      expect(item).to be_valid
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(pending: 0, imported: 1, skipped: 2, error: 3) }
  end

  describe "scopes" do
    describe ".recent" do
      it "orders by detected_at descending" do
        feed = create(:rss_feed)
        old_item = create(:rss_feed_item, rss_feed: feed, detected_at: 2.days.ago)
        new_item = create(:rss_feed_item, rss_feed: feed, detected_at: 1.hour.ago)

        expect(described_class.recent).to eq([new_item, old_item])
      end
    end
  end
end
