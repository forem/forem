require "rails_helper"

RSpec.describe Feeds::CheckItemPreviouslyImported, type: :service do
  let(:user) { create(:user) }
  let(:title) { "Test Article Title" }
  let(:url) { "https://example.com/post-1?source=rss" }
  let(:item) { instance_double(Feedjira::Parser::RSSEntry, title: title, url: url) }

  describe ".call" do
    it "returns false when item is nil" do
      expect(described_class.call(nil, user)).to be(false)
    end

    it "returns false when item url is blank" do
      blank_url_item = instance_double(Feedjira::Parser::RSSEntry, title: "Title", url: "")
      expect(described_class.call(blank_url_item, user)).to be(false)
    end

    it "returns false when item title is blank" do
      blank_title_item = instance_double(Feedjira::Parser::RSSEntry, title: "", url: "https://example.com/post")
      expect(described_class.call(blank_title_item, user)).to be(false)
    end

    it "returns true when user has an article with the same title" do
      create(:article, user: user, title: title)
      expect(described_class.call(item, user)).to be(true)
    end

    it "returns true when user has an article with the same normalized feed_source_url" do
      create(:article, user: user, feed_source_url: "https://example.com/post-1")
      expect(described_class.call(item, user)).to be(true)
    end

    it "returns false when user has no matching article" do
      expect(described_class.call(item, user)).to be(false)
    end
  end
end
