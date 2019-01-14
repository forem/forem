require "rails_helper"
require "rss"

vcr_option = {
  cassette_name: "rss_feeds",
  allow_playback_repeats: "true"
}

RSpec.describe RssReader, vcr: vcr_option do
  let(:link) { "https://medium.com/feed/@vaidehijoshi" }
  let(:nonmedium_link) { "https://circleci.com/blog/feed.xml" }
  let(:nonpermanent_link) { "https://medium.com/feed/@macsiri/" }
  let(:rss_data) { RSS::Parser.parse(HTTParty.get(link).body, false) }

  describe "#get_all_articles" do
    before do
      [link, nonmedium_link, nonpermanent_link].each do |feed_url|
        create(:user, feed_url: feed_url)
      end
    end

    it "fetch only articles from an feed_url" do
      described_class.get_all_articles
      # the result within the approval file depends on the feed
      # not fetching comments is baked into this
      verify(format: :txt) { Article.count }
    end

    it "does not re-create article if it already exist" do
      described_class.new.get_all_articles
      expect { described_class.new.get_all_articles }.not_to change(Article, :count)
    end

    it "parses correctly" do
      described_class.new.get_all_articles
      verify format: :txt do
        User.find_by(feed_url: nonpermanent_link).articles.first.body_markdown
      end
    end

    it "gets articles for user" do
      # the result within the approval file depends on the feed
      described_class.new.fetch_user(User.first)
      verify(format: :txt) { Article.count }
    end

    it "does not set featured_number" do
      described_class.new.fetch_user(User.first)
      expect(Article.all.map(&:featured_number).uniq).to eq([nil])
    end
  end

  describe "#valid_feed_url?" do
    it "returns true on valid feed url" do
      expect(described_class.new.valid_feed_url?(link)).to be true
    end

    it "returns false on invalid feed url" do
      bad_link = "www.google.com"
      expect(described_class.new.valid_feed_url?(bad_link)).to be false
    end
  end
end
