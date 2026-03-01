require "rails_helper"

RSpec.describe RssFeed do
  let(:user) { create(:user) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:fallback_organization).class_name("Organization").optional }
    it { is_expected.to belong_to(:fallback_author).class_name("User").optional }
    it { is_expected.to have_many(:rss_feed_items).dependent(:destroy) }
    it { is_expected.to have_many(:articles).dependent(:nullify) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:feed_url) }
    it { is_expected.to validate_length_of(:feed_url).is_at_most(500) }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }

    it "validates uniqueness of feed_url scoped to user" do
      allow(Feeds::ValidateUrl).to receive(:call).and_return(true)
      create(:rss_feed, user: user, feed_url: "https://example.com/feed.xml")
      feed = build(:rss_feed, user: user, feed_url: "https://example.com/feed.xml")
      expect(feed).not_to be_valid
      expect(feed.errors[:feed_url]).to be_present
    end

    it "allows same feed_url for different users" do
      create(:rss_feed, user: user, feed_url: "https://example.com/feed.xml")
      other_user = create(:user)
      feed = build(:rss_feed, user: other_user, feed_url: "https://example.com/feed.xml")
      # Skip URL validation since we don't have a real feed server
      allow(Feeds::ValidateUrl).to receive(:call).and_return(true)
      expect(feed).to be_valid
    end
  end

  describe "enums" do
    it { is_expected.to define_enum_for(:status).with_values(active: 0, paused: 1, error: 2) }
  end

  describe "scopes" do
    describe ".fetchable" do
      it "returns only active feeds" do
        active = create(:rss_feed, user: user, status: :active)
        create(:rss_feed, user: create(:user), status: :paused)
        create(:rss_feed, user: create(:user), status: :error)

        expect(described_class.fetchable).to eq([active])
      end
    end
  end

  describe "fallback organization validation" do
    it "allows setting fallback organization when user is org admin" do
      org = create(:organization)
      create(:organization_membership, user: user, organization: org, type_of_user: "admin")
      feed = build(:rss_feed, user: user, fallback_organization: org)
      allow(Feeds::ValidateUrl).to receive(:call).and_return(true)
      expect(feed).to be_valid
    end

    it "rejects fallback organization when user is not org admin" do
      org = create(:organization)
      feed = build(:rss_feed, user: user, fallback_organization: org)
      allow(Feeds::ValidateUrl).to receive(:call).and_return(true)
      expect(feed).not_to be_valid
      expect(feed.errors[:fallback_organization]).to be_present
    end
  end
end
