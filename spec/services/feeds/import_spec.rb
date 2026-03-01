require "rails_helper"

RSpec.describe Feeds::Import, :vcr, type: :service do
  let(:link) { "https://medium.com/feed/@vaidehijoshi" }
  let(:nonmedium_link) { "https://circleci.com/blog/feed.xml" }
  let(:nonpermanent_link) { "https://medium.com/feed/@macsiri/" }

  before do
    [link, nonmedium_link, nonpermanent_link].each do |feed_url|
      user = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)
      create(:rss_feed, user: user, feed_url: feed_url, status: :active)
    end
  end

  describe ".call" do
    it "filters to feeds for users with recent article or presence activity" do
      recent_article_user = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)
      create(:rss_feed, user: recent_article_user, feed_url: "#{link}?u=1", status: :active)
      recent_present_user = create(:user, last_presence_at: 2.weeks.ago)
      create(:rss_feed, user: recent_present_user, feed_url: "#{link}?u=2", status: :active)
      stale_user = create(:user, last_article_at: 6.months.ago, last_presence_at: 6.months.ago)
      create(:rss_feed, user: stale_user, feed_url: "#{link}?u=3", status: :active)

      scoped_feeds = RssFeed.where(user_id: [recent_article_user.id, recent_present_user.id, stale_user.id])
      importer = described_class.new(rss_feeds_scope: scoped_feeds)
      filtered = importer.__send__(:filter_feeds, rss_feeds_scope: scoped_feeds, earlier_than: nil)

      filtered_user_ids = filtered.pluck(:user_id)
      expect(filtered_user_ids).to contain_exactly(recent_article_user.id, recent_present_user.id)
    end

    it "ensures that we only fetch feeds for users who can create articles", vcr: { cassette_name: "feeds_import" } do
      allow(ArticlePolicy).to receive(:scope_users_authorized_to_action).and_call_original

      described_class.call

      expect(ArticlePolicy).to have_received(:scope_users_authorized_to_action).with(users_scope: User, action: :create)
    end

    # TODO: We could probably improve these tests by parsing against the items in the feed rather than hardcoding
    it "fetch only articles from a feed_url", vcr: { cassette_name: "feeds_import" } do
      num_articles = described_class.call

      expect(num_articles).to eq(21)
    end

    it "subscribes the article author to comments", vcr: { cassette_name: "feeds_import" } do
      expect { described_class.call }
        .to change { NotificationSubscription.where(notifiable_type: "Article", config: "all_comments").count }
        .from(0)
    end

    it "does not recreate articles if they already exist", vcr: { cassette_name: "feeds_import_twice" } do
      described_class.call

      expect { described_class.call }.not_to change(Article, :count)
    end

    it "parses correctly", vcr: { cassette_name: "feeds_import" } do
      expect do
        described_class.call
      end.to change(RssFeed.find_by(feed_url: nonpermanent_link).user.articles, :count).by(1)
    end

    it "sets last_fetched_at to the current time", vcr: { cassette_name: "feeds_import" } do
      Timecop.freeze(Time.current) do
        described_class.call

        rss_feed = RssFeed.find_by(feed_url: nonpermanent_link)
        expect(rss_feed.last_fetched_at.to_i).to eq(Time.current.to_i)
      end
    end

    it "creates RssFeedItem records for imported articles", vcr: { cassette_name: "feeds_import" } do
      expect { described_class.call }.to change(RssFeedItem, :count)

      expect(RssFeedItem.imported.count).to be_positive
    end

    it "queues as many slack messages as there are articles", vcr: { cassette_name: "feeds_import" } do
      expect do
        described_class.call
      end.to change(Slack::WorkflowWebhookWorker.jobs, :count).by(3) # 3 users
    end

    context "when handling errors", vcr: { cassette_name: "feeds_import" } do
      it "reports an notification subscription creation error" do
        allow(NotificationSubscription).to receive(:create!).and_raise(StandardError)
        allow(Rails.logger).to receive(:error)

        described_class.call

        expect(Rails.logger).to have_received(:error).at_least(:once)
      end

      it "reports an article creation error" do
        allow(Article).to receive(:create!).and_raise(StandardError)
        allow(Rails.logger).to receive(:error)

        described_class.call

        expect(Rails.logger).to have_received(:error).at_least(:once)
      end

      it "reports a fetching error" do
        allow(HTTParty).to receive(:get).and_raise(StandardError)
        allow(Rails.logger).to receive(:error)

        described_class.call

        expect(Rails.logger).to have_received(:error).at_least(:once)
      end

      it "reports a parsing error" do
        allow(Feedjira).to receive(:parse).and_raise(StandardError)
        allow(Rails.logger).to receive(:error)

        described_class.call

        expect(Rails.logger).to have_received(:error).at_least(:once)
      end

      it "logs the error message" do
        allow(Feedjira).to receive(:parse).and_raise("this is an error")
        allow(Rails.logger).to receive(:error)

        described_class.call

        expect(Rails.logger).to have_received(:error).at_least(:once).with(/error_message=>"this is an error"/)
      end
    end

    context "with an explicit set of feeds", vcr: { cassette_name: "feeds_import" } do
      # TODO: We could probably improve these tests by parsing against the items in the feed rather than hardcoding
      it "accepts a subset of feeds" do
        num_articles = described_class.call(
          rss_feeds_scope: RssFeed.fetchable.limit(1),
        )

        expect(num_articles).to eq(10)
      end
    end
  end

  context "when refetching" do
    it "does refetch same feed over and over by default", vcr: { cassette_name: "feeds_import_multiple_times" } do
      rss_feed = RssFeed.find_by(feed_url: nonpermanent_link)

      Timecop.freeze(Time.current) do
        rss_feed.update_columns(last_fetched_at: Time.current)

        fetched_at_time = rss_feed.reload.last_fetched_at

        # travel a few seconds in the future to simulate a new time
        3.times do |i|
          Timecop.travel((i + 5).seconds.from_now) do
            described_class.call
          end
        end

        expect(rss_feed.reload.last_fetched_at > fetched_at_time).to be(true)
      end
    end

    it "does not refetch recently fetched feeds if earlier_than is given", vcr: { cassette_name: "feeds_import" } do
      time = 30.minutes.ago

      Timecop.freeze(time) do
        described_class.call
      end

      # we delete the articles to make sure it won't trigger the duplicate check
      Article.delete_all

      expect { described_class.call(earlier_than: 1.hour.ago) }.not_to change(Article, :count)
    end

    it "refetches recently fetched feeds if earlier_than is now", vcr: { cassette_name: "feeds_import_twice" } do
      time = 30.minutes.ago

      Timecop.freeze(time) do
        described_class.call
      end

      # we delete the articles to make sure it won't trigger the duplicate check
      Article.delete_all

      expect { described_class.call(earlier_than: Time.current) }.to change(Article, :count)
    end
  end

  context "when feed_referential_link is false" do
    it "does not self-reference links for user", vcr: { cassette_name: "feeds_import_non_referential" } do
      # Article.find_by is used by find_and_replace_possible_links!
      # checking its invocation is a shortcut to testing the functionality.
      allow(Article).to receive(:find_by).and_call_original

      user = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)
      create(:rss_feed, user: user, feed_url: nonpermanent_link, referential_link: false, status: :active)

      described_class.call

      expect(Article).not_to have_received(:find_by)
    end
  end

  describe "feeds parsing and regressions" do
    it "parses https://medium.com/feed/@dvirsegal correctly", vcr: { cassette_name: "rss_reader_dvirsegal" } do
      user = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)
      create(:rss_feed, user: user, feed_url: "https://medium.com/feed/@dvirsegal", status: :active)

      expect do
        described_class.call(rss_feeds_scope: RssFeed.where(user_id: user.id))
      end.to change(user.articles, :count).by(10)
    end

    it "converts/replaces <picture> tags to <img>", vcr: { cassette_name: "rss_reader_swimburger" } do
      user = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)
      create(:rss_feed, user: user, feed_url: "https://swimburger.net/atom.xml", status: :active)

      expect do
        described_class.call(rss_feeds_scope: RssFeed.where(user_id: user.id))
      end.to change(user.articles, :count).by(10)

      body_markdown = user.articles.last.body_markdown

      expect(body_markdown).not_to include("<picture>")
      expected_image_markdown =
        "![Screenshot of Azure left navigation pane](https://swimburger.net/media/lxypkhak/azure-create-a-resource.png)"

      expect(body_markdown).to include(expected_image_markdown)
    end
  end

  context "when multiple users fetch from the same feed_url", vcr: { cassette_name: "feeds_import_two_users" } do
    it "fetches the articles in both accounts (if mark_canonical = false)" do
      rss_feed_user1 = RssFeed.find_by(feed_url: link).user
      rss_feed_user2 = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)
      create(:rss_feed, user: rss_feed_user2, feed_url: "#{link}?dup", status: :active)

      expect do
        described_class.call(rss_feeds_scope: RssFeed.where(feed_url: [link, "#{link}?dup"]))
      end
        .to change(rss_feed_user1.articles, :count).by(10)
        .and change(rss_feed_user2.articles, :count).by(10)
    end
  end
end
