require "rails_helper"

RSpec.describe Feeds::Import, :vcr, type: :service do
  let(:link) { "https://medium.com/feed/@vaidehijoshi" }
  let(:nonmedium_link) { "https://circleci.com/blog/feed.xml" }
  let(:nonpermanent_link) { "https://medium.com/feed/@macsiri/" }

  before do
    allow(Feeds::ValidateUrl).to receive(:call).and_return(true)
    [link, nonmedium_link, nonpermanent_link].each do |feed_url|
      user = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)
      RssFeed.create!(user: user, url: feed_url)
    end
  end

  describe ".call" do
    it "filters feeds that need fetching" do
      recent_article_user = create(:user)
      feed1 = RssFeed.create!(user: recent_article_user, url: "http://example.com/1", last_fetched_at: nil)
      feed2 = RssFeed.create!(user: recent_article_user, url: "http://example.com/2", last_fetched_at: 2.weeks.ago)
      feed3 = RssFeed.create!(user: recent_article_user, url: "http://example.com/3", last_fetched_at: 1.minute.ago)

      scoped_feeds = RssFeed.where(id: [feed1.id, feed2.id, feed3.id])
      importer = described_class.new(feeds_scope: scoped_feeds, earlier_than: 1.hour.ago)
      filtered = importer.send(:filter_feeds_from, feeds_scope: scoped_feeds, earlier_than: 1.hour.ago)

      expect(filtered.pluck(:id)).to contain_exactly(feed1.id, feed2.id)
    end

    it "fetch only articles from feeds", vcr: { cassette_name: "feeds_import" } do
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
      feed = RssFeed.find_by(url: nonpermanent_link)
      expect do
        described_class.call
      end.to change(feed.user.articles, :count).by(1)
    end

    it "sets last_fetched_at to the current time", vcr: { cassette_name: "feeds_import" } do
      Timecop.freeze(Time.current) do
        described_class.call
        feed = RssFeed.find_by(url: nonpermanent_link)
        expect(feed.last_fetched_at.to_i).to eq(Time.current.to_i)
      end
    end

    it "queues as many slack messages as there are articles", vcr: { cassette_name: "feeds_import" } do
      expect do
        described_class.call
      end.to change(Slack::WorkflowWebhookWorker.jobs, :count).by(3) # 3 feeds
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
  end

  context "when refetching" do
    it "does not refetch recently fetched feeds if earlier_than is given", vcr: { cassette_name: "feeds_import" } do
      time = 30.minutes.ago
      Timecop.freeze(time) do
        described_class.call
      end

      Article.delete_all

      expect { described_class.call(earlier_than: 1.hour.ago) }.not_to change(Article, :count)
    end

    it "refetches recently fetched feeds if earlier_than is now", vcr: { cassette_name: "feeds_import_twice" } do
      time = 30.minutes.ago
      Timecop.freeze(time) do
        described_class.call
      end

      Article.delete_all

      expect { described_class.call(earlier_than: Time.current) }.to change(Article, :count)
    end
  end

  context "when referential_link is false" do
    it "does not self-reference links for user", vcr: { cassette_name: "feeds_import_non_referential" } do
      allow(Article).to receive(:find_by).and_call_original

      user = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)
      feed = RssFeed.create!(user: user, url: nonpermanent_link, referential_link: false)

      described_class.call(feeds_scope: RssFeed.where(id: feed.id))

      expect(Article).not_to have_received(:find_by)
    end
  end
end
