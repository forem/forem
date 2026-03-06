require "rails_helper"

RSpec.describe Feeds::ResolveAuthor do
  let(:feed_owner) { create(:user) }
  let(:feed_source) { build(:feed_source, user: feed_owner) }

  before do
    allow(Feeds::ValidateUrl).to receive(:call).and_return(true)
  end

  def item_with_author(author_string)
    double("FeedItem", author: author_string)
  end

  describe ".call" do
    context "when RSS author matches a user by email" do
      it "returns the matched user" do
        matching_user = create(:user, email: "alice@example.com")
        item = item_with_author("alice@example.com")

        result = described_class.call(item, feed_source)
        expect(result).to eq(matching_user)
      end

      it "extracts email from 'Name <email>' format" do
        matching_user = create(:user, email: "bob@example.com")
        item = item_with_author("Bob Smith <bob@example.com>")

        result = described_class.call(item, feed_source)
        expect(result).to eq(matching_user)
      end
    end

    context "when RSS author matches a user by name" do
      it "returns the matched user" do
        matching_user = create(:user, name: "Alice Johnson")
        item = item_with_author("Alice Johnson")

        result = described_class.call(item, feed_source)
        expect(result).to eq(matching_user)
      end

      it "strips email and matches by name" do
        matching_user = create(:user, name: "Bob Smith")
        item = item_with_author("Bob Smith <unknown@other.com>")

        result = described_class.call(item, feed_source)
        expect(result).to eq(matching_user)
      end
    end

    context "when RSS author does not match any user" do
      it "falls back to feed source default author" do
        default_author = create(:user)
        feed_source.author = default_author

        item = item_with_author("Unknown Person")
        result = described_class.call(item, feed_source)
        expect(result).to eq(default_author)
      end

      it "falls back to feed source owner when no default author" do
        item = item_with_author("Unknown Person")
        result = described_class.call(item, feed_source)
        expect(result).to eq(feed_owner)
      end
    end

    context "when RSS item has no author" do
      it "returns feed source effective author" do
        item = item_with_author(nil)
        result = described_class.call(item, feed_source)
        expect(result).to eq(feed_owner)
      end

      it "returns feed source effective author for blank author" do
        item = item_with_author("  ")
        result = described_class.call(item, feed_source)
        expect(result).to eq(feed_owner)
      end
    end

    context "when item does not respond to author" do
      it "returns feed source effective author" do
        item = double("FeedItem")
        allow(item).to receive(:try).with(:author).and_return(nil)
        result = described_class.call(item, feed_source)
        expect(result).to eq(feed_owner)
      end
    end
  end
end
