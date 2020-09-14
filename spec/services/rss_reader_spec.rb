require "rails_helper"
require "rss"

RSpec.describe RssReader, type: :service, vcr: true, db_strategy: :truncation do
  self.use_transactional_tests = false

  let(:link) { "https://medium.com/feed/@vaidehijoshi" }
  let(:nonmedium_link) { "https://circleci.com/blog/feed.xml" }
  let(:nonpermanent_link) { "https://medium.com/feed/@macsiri/" }
  let(:rss_data) { RSS::Parser.parse(HTTParty.get(link).body, false) }
  let!(:rss_reader) { described_class.new }

  describe "#get_all_articles" do
    before do
      [link, nonmedium_link, nonpermanent_link].each do |feed_url|
        create(:user, feed_url: feed_url)
      end
    end

    it "fetch only articles from a feed_url", vcr: { cassette_name: "rss_reader_fetch_articles" } do
      articles = rss_reader.get_all_articles

      # the result within the approval file depends on the feed
      # not fetching comments is baked into this
      verify(format: :txt) { articles.length }
    end

    it "does not recreate articles if they already exist", vcr: { cassette_name: "rss_reader_fetch_articles_twice" } do
      rss_reader.get_all_articles

      expect { rss_reader.get_all_articles }.not_to change(Article, :count)
    end

    it "parses correctly", vcr: { cassette_name: "rss_reader_fetch_articles" } do
      rss_reader.get_all_articles

      verify format: :txt do
        User.find_by(feed_url: nonpermanent_link).articles.first.body_markdown
      end
    end

    it "sets feed_fetched_at to the current time", vcr: { cassette_name: "rss_reader_fetch_articles" } do
      Timecop.freeze(Time.current) do
        rss_reader.get_all_articles

        user = User.find_by(feed_url: nonpermanent_link)
        feed_fetched_at = user.feed_fetched_at
        expect(feed_fetched_at.to_i).to eq(Time.current.to_i)
      end
    end

    it "does refetch same user over and over by default", vcr: { cassette_name: "rss_reader_fetch_multiple_times" } do
      user = User.find_by(feed_url: nonpermanent_link)

      Timecop.freeze(Time.current) do
        user.update_columns(feed_fetched_at: Time.current)

        fetched_at_time = user.reload.feed_fetched_at

        # travel a few seconds in the future to simulate a new time
        3.times do |i|
          Timecop.travel((i + 5).seconds.from_now) do
            rss_reader.get_all_articles
          end
        end

        expect(user.reload.feed_fetched_at > fetched_at_time).to be(true)
      end
    end

    it "reports an article creation error" do
      allow(rss_reader).to receive(:make_from_rss_item).and_raise(StandardError)
      allow(Honeybadger).to receive(:notify)

      rss_reader.get_all_articles

      expect(Honeybadger).to have_received(:notify).at_least(:once)
    end

    it "reports a fetching error" do
      allow(rss_reader).to receive(:fetch_rss).and_raise(StandardError)
      allow(Honeybadger).to receive(:notify)

      rss_reader.get_all_articles

      expect(Honeybadger).to have_received(:notify).at_least(:once)
    end

    it "queues as many slack messages as there are articles", vcr: { cassette_name: "rss_reader_fetch_articles" } do
      old_count = Slack::Messengers::Worker.jobs.count
      articles = rss_reader.get_all_articles
      expect(Slack::Messengers::Worker.jobs.count).to eq(old_count + articles.length)
    end
  end

  context "when feed_referential_link is false" do
    it "does not self-reference links for user" do
      # Article.find_by is used by find_and_replace_possible_links!
      # checking its invocation is a shortcut to testing the functionality.
      allow(Article).to receive(:find_by).and_call_original

      create(:user, feed_url: nonpermanent_link, feed_referential_link: false)

      rss_reader.get_all_articles

      expect(Article).not_to have_received(:find_by)
    end
  end

  describe "#fetch_user", vcr: { cassette_name: "rss_reader_fetch_medium_feed" } do
    before do
      [link, nonmedium_link, nonpermanent_link].each do |feed_url|
        create(:user, feed_url: feed_url)
      end
    end

    it "gets articles for user" do
      articles = rss_reader.fetch_user(User.find_by(feed_url: link))

      # the result within the approval file depends on the feed
      verify(format: :txt) { articles.length }
    end

    it "does not set featured_number" do
      user = User.find_by(feed_url: link)
      rss_reader.fetch_user(user)

      expect(user.articles.select(&:featured_number)).to be_empty
    end

    it "reports an article creation error on the standard logger" do
      allow(rss_reader).to receive(:make_from_rss_item).and_raise(StandardError)
      allow(Honeybadger).to receive(:notify)

      rss_reader.fetch_user(User.find_by(feed_url: link))

      expect(Honeybadger).to have_received(:notify).at_least(:once)
    end

    it "reports a fetching error on the standard logger" do
      allow(rss_reader).to receive(:fetch_rss).and_raise(StandardError)
      allow(Honeybadger).to receive(:notify)

      rss_reader.fetch_user(User.find_by(feed_url: link))

      expect(Honeybadger).to have_received(:notify).at_least(:once)
    end

    it "queues as many slack messages as there are user articles" do
      old_count = Slack::Messengers::Worker.jobs.count
      articles = rss_reader.fetch_user(User.find_by(feed_url: link))
      expect(Slack::Messengers::Worker.jobs.count).to eq(old_count + articles.length)
    end
  end

  describe "#valid_feed_url?" do
    it "returns true on valid feed url" do
      expect(rss_reader.valid_feed_url?(link)).to be(true)
    end

    it "returns false on invalid feed url" do
      bad_link = "www.google.com"
      expect(rss_reader.valid_feed_url?(bad_link)).to be(false)
    end
  end

  describe "feeds parsing and regressions" do
    it "parses https://medium.com/feed/@dvirsegal correctly", vcr: { cassette_name: "rss_reader_dvirsegal" } do
      user = create(:user, feed_url: "https://medium.com/feed/@dvirsegal")

      expect do
        rss_reader.fetch_user(user)
      end.to change(user.articles, :count).by(10)
    end

    it "converts/replaces <picture> tags to <img>", vcr: { cassette_name: "rss_reader_swimburger" } do
      user = create(:user, feed_url: "https://swimburger.net/atom.xml")

      expect do
        rss_reader.fetch_user(user)
      end.to change(user.articles, :count).by(10)

      body_markdown = user.articles.last.body_markdown

      expect(body_markdown).not_to include("<picture>")
      expected_image_markdown =
        "![Screenshot of Azure left navigation pane](https://swimburger.net/media/lxypkhak/azure-create-a-resource.png)"

      expect(body_markdown).to include(expected_image_markdown)
    end
  end
end
