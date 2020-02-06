require "rails_helper"
require "rss"

vcr_option = {
  cassette_name: "rss_feeds",
  allow_playback_repeats: "true"
}

default_logger = Rails.logger

RSpec.describe RssReader, type: :service, vcr: vcr_option do
  let(:link) { "https://medium.com/feed/@vaidehijoshi" }
  let(:nonmedium_link) { "https://circleci.com/blog/feed.xml" }
  let(:nonpermanent_link) { "https://medium.com/feed/@macsiri/" }
  let(:rss_data) { RSS::Parser.parse(HTTParty.get(link).body, false) }

  # Override the default Rails logger as these tests require the Timber logger.
  before do
    timber_logger = Timber::Logger.new(nil)
    Rails.logger = ActiveSupport::TaggedLogging.new(timber_logger)
  end

  after { Rails.logger = default_logger }

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

    it "sets time current" do
      described_class.new.get_all_articles
      expect(User.find_by(feed_url: nonpermanent_link).feed_fetched_at).to be > 2.minutes.ago
    end

    it "does refetch same user over and over by default" do
      user = User.find_by(feed_url: nonpermanent_link)
      Timecop.freeze(Time.current) do
        user.update_column(:feed_fetched_at, Time.current)
        fetched_at_time = user.reload.feed_fetched_at
        # travel a few seconds in the future to simulate a new time
        3.times do |i|
          Timecop.travel((i + 5).seconds.from_now) { described_class.new.get_all_articles }
        end
        expect(user.reload.feed_fetched_at > fetched_at_time).to be(true)
      end
    end

    it "logs an article creation error" do
      reader = described_class.new
      allow(reader).to receive(:make_from_rss_item).and_raise(StandardError)
      allow(Rails.logger).to receive(:error)
      reader.get_all_articles
      expect(Rails.logger).to have_received(:error).at_least(:once)
    end

    it "logs a fetching error" do
      reader = described_class.new
      allow(reader).to receive(:fetch_rss).and_raise(StandardError)
      allow(Rails.logger).to receive(:error)
      reader.get_all_articles
      expect(Rails.logger).to have_received(:error).at_least(:once)
    end
  end

  context "when feed_referential_link is false" do
    it "does not self-reference links for user" do
      # Article.find_by is used by find_and_replace_possible_links!
      # checking it's invocation s a shortcut to testing the functionality.
      allow(Article).to receive(:find_by).and_call_original
      create(:user, feed_url: nonpermanent_link, feed_referential_link: false)
      described_class.get_all_articles
      expect(Article).not_to have_received(:find_by)
    end
  end

  describe "#fetch_user" do
    before do
      [link, nonmedium_link, nonpermanent_link].each do |feed_url|
        create(:user, feed_url: feed_url)
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

    it "logs an article creation error on the standard logger" do
      reader = described_class.new
      allow(reader).to receive(:make_from_rss_item).and_raise(StandardError)
      allow(Rails.logger).to receive(:error)
      reader.fetch_user(User.first)
      expect(Rails.logger).to have_received(:error).at_least(:once)
    end

    it "logs a fetching error on the standard logger" do
      reader = described_class.new
      allow(reader).to receive(:fetch_rss).and_raise(StandardError)
      allow(Rails.logger).to receive(:error)
      reader.fetch_user(User.first)
      expect(Rails.logger).to have_received(:error).at_least(:once)
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
