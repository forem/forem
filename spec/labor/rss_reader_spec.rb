require "rails_helper"
require "rss"
require "open-uri"

vcr_option = {
  cassette_name: "rss_feeds",
  allow_playback_repeats: "true",
}

RSpec.describe RssReader, vcr: vcr_option do
  let(:link) { "https://medium.com/feed/@vaidehijoshi" }
  let(:nonmedium_link) { "https://circleci.com/blog/feed.xml" }
  let(:nonpermanent_link) { "https://medium.com/feed/@macsiri/" }
  let(:rss_data) { RSS::Parser.parse(open(link).read, false) }

  describe "#get_all_articles" do
    before do
      [link, nonmedium_link, nonpermanent_link].each do |feed_url|
        create(:user, feed_url: feed_url)
      end
    end

    it "fetch only articles from an feed_url" do
      described_class.get_all_articles
      # the 16 here depends on the fixture
      # not fetching comments is baked into this
      expect(Article.all.length).to be > 10
    end

    it "does not re-create article if it already exist" do
      described_class.new.get_all_articles
      article_count_before = Article.all.length
      described_class.new.get_all_articles
      expect(Article.all.length).to eq(article_count_before)
    end

    it "gets articles for user" do
      described_class.new.fetch_user(User.first)
      # the 7 here depends on the fixture
      # not fetching comments is baked into this
      expect(Article.all.length).to be > 2
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
