require "rails_helper"

RSpec.describe Feeds::Import, type: :service, vcr: true do
  let(:link) { "https://medium.com/feed/@vaidehijoshi" }
  let(:nonmedium_link) { "https://circleci.com/blog/feed.xml" }
  let(:nonpermanent_link) { "https://medium.com/feed/@macsiri/" }

  before do
    [link, nonmedium_link, nonpermanent_link].each do |feed_url|
      user = create(:user)
      user.setting.update(feed_url: feed_url)
    end
  end

  describe ".call" do
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
      end.to change(Users::Setting.find_by(feed_url: nonpermanent_link).user.articles, :count).by(1)
    end

    it "sets feed_fetched_at to the current time", vcr: { cassette_name: "feeds_import" } do
      Timecop.freeze(Time.current) do
        described_class.call

        user = Users::Setting.find_by(feed_url: nonpermanent_link).user
        feed_fetched_at = user.feed_fetched_at
        expect(feed_fetched_at.to_i).to eq(Time.current.to_i)
      end
    end

    it "queues as many slack messages as there are articles", vcr: { cassette_name: "feeds_import" } do
      old_count = Slack::Messengers::Worker.jobs.count
      num_articles = described_class.call
      expect(Slack::Messengers::Worker.jobs.count).to eq(old_count + num_articles)
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

    context "with an explicit set of users", vcr: { cassette_name: "feeds_import" } do
      # TODO: We could probably improve these tests by parsing against the items in the feed rather than hardcoding
      it "accepts a subset of users" do
        num_articles = described_class.call(users: User.where(id: Users::Setting.with_feed.select(:user_id)).limit(1))

        expect(num_articles).to eq(10)
      end

      it "imports no articles if given users are without feed" do
        user = create(:user)
        user.setting.update(feed_url: nil)

        # rubocop:disable Layout/LineLength
        expect(described_class.call(users: User.where(id: Users::Setting.where(feed_url: nil).select(:user_id)))).to eq(0)
        # rubocop:enable Layout/LineLength
      end
    end
  end

  context "when refetching" do
    it "does refetch same user over and over by default", vcr: { cassette_name: "feeds_import_multiple_times" } do
      user = Users::Setting.find_by(feed_url: nonpermanent_link).user

      Timecop.freeze(Time.current) do
        user.update_columns(feed_fetched_at: Time.current)

        fetched_at_time = user.reload.feed_fetched_at

        # travel a few seconds in the future to simulate a new time
        3.times do |i|
          Timecop.travel((i + 5).seconds.from_now) do
            described_class.call
          end
        end

        expect(user.reload.feed_fetched_at > fetched_at_time).to be(true)
      end
    end

    it "does not refetch recently fetched users if earlier_than is given", vcr: { cassette_name: "feeds_import" } do
      time = 30.minutes.ago

      Timecop.freeze(time) do
        described_class.call
      end

      # we delete the articles to make sure it won't trigger the duplicate check
      Article.delete_all

      expect { described_class.call(earlier_than: 1.hour.ago) }.not_to change(Article, :count)
    end

    it "refetches recently fetched users if earlier_than is now", vcr: { cassette_name: "feeds_import_twice" } do
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

      user = create(:user)
      user.setting.update(feed_url: nonpermanent_link, feed_referential_link: false)

      described_class.call

      expect(Article).not_to have_received(:find_by)
    end
  end

  describe "feeds parsing and regressions" do
    it "parses https://medium.com/feed/@dvirsegal correctly", vcr: { cassette_name: "rss_reader_dvirsegal" } do
      user = create(:user)
      user.setting.update(feed_url: "https://medium.com/feed/@dvirsegal")

      expect do
        described_class.call(users: User.where(id: user.id))
      end.to change(user.articles, :count).by(10)
    end

    it "converts/replaces <picture> tags to <img>", vcr: { cassette_name: "rss_reader_swimburger" } do
      user = create(:user)
      user.setting.update(feed_url: "https://swimburger.net/atom.xml")

      expect do
        described_class.call(users: User.where(id: user.id))
      end.to change(user.articles, :count).by(10)

      body_markdown = user.articles.last.body_markdown

      expect(body_markdown).not_to include("<picture>")
      expected_image_markdown =
        "![Screenshot of Azure left navigation pane](https://swimburger.net/media/lxypkhak/azure-create-a-resource.png)"

      expect(body_markdown).to include(expected_image_markdown)
    end
  end

  context "when multiple users fetch from the same feed_url" do
    it "fetches the articles in both accounts (if feed_mark_canonical = false)" do
      rss_feed_user1 = Users::Setting.find_by(feed_url: link).user
      rss_feed_user2 = create(:user)
      rss_feed_user2.setting.update!(feed_url: link)
      expect { described_class.call(users: User.where(id: Users::Setting.where(feed_url: link).select(:user_id))) }
        .to change(rss_feed_user1.articles, :count).by(10)
        .and change(rss_feed_user2.articles, :count).by(10)
    end

    it "fetches the articles in both accounts (if feed_mark_canonical = true)" do
      rss_feed_user1 = Users::Setting.find_by(feed_url: link).user
      rss_feed_user1.setting.update!(feed_mark_canonical: true)
      rss_feed_user2 = create(:user)
      rss_feed_user2.setting.update!(feed_url: link, feed_mark_canonical: true)
      expect { described_class.call(users: User.where(id: Users::Setting.where(feed_url: link).select(:user_id))) }
        .to change(rss_feed_user1.articles, :count).by(10)
        .and change(rss_feed_user2.articles, :count).by(10)
    end
  end
end
