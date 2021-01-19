require "rails_helper"

RSpec.describe Feeds::Import, type: :service, vcr: true, db_strategy: :truncation do
  self.use_transactional_tests = false

  let(:link) { "https://medium.com/feed/@vaidehijoshi" }
  let(:nonmedium_link) { "https://circleci.com/blog/feed.xml" }
  let(:nonpermanent_link) { "https://medium.com/feed/@macsiri/" }

  describe ".call" do
    before do
      [link, nonmedium_link, nonpermanent_link].each do |feed_url|
        create(:user, feed_url: feed_url)
      end
    end

    it "fetch only articles from a feed_url", vcr: { cassette_name: "feeds_import" } do
      num_articles = described_class.call

      verify(format: :txt) { num_articles }
    end

    it "does not recreate articles if they already exist", vcr: { cassette_name: "feeds_import_twice" } do
      described_class.call

      expect { described_class.call }.not_to change(Article, :count)
    end

    it "parses correctly", vcr: { cassette_name: "feeds_import" } do
      described_class.call

      verify format: :txt do
        User.find_by(feed_url: nonpermanent_link).articles.first.body_markdown
      end
    end

    it "sets feed_fetched_at to the current time", vcr: { cassette_name: "feeds_import" } do
      Timecop.freeze(Time.current) do
        described_class.call

        user = User.find_by(feed_url: nonpermanent_link)
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
      it "accepts a subset of users" do
        num_articles = described_class.call(users: User.with_feed.limit(1))

        verify(format: :txt) { num_articles }
      end

      it "imports no articles if given users are without feed" do
        create(:user, feed_url: nil)

        described_class.call(users: User.where(feed_url: nil))
        verify(format: :txt) { 0 }
      end
    end
  end

  context "when refetching" do
    before do
      [link, nonmedium_link, nonpermanent_link].each do |feed_url|
        create(:user, feed_url: feed_url)
      end
    end

    it "does refetch same user over and over by default", vcr: { cassette_name: "feeds_import_multiple_times" } do
      user = User.find_by(feed_url: nonpermanent_link)

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

      create(:user, feed_url: nonpermanent_link, feed_referential_link: false)

      described_class.call

      expect(Article).not_to have_received(:find_by)
    end
  end

  describe "feeds parsing and regressions" do
    it "parses https://medium.com/feed/@dvirsegal correctly", vcr: { cassette_name: "rss_reader_dvirsegal" } do
      user = create(:user, feed_url: "https://medium.com/feed/@dvirsegal")

      expect do
        described_class.call(users: User.where(id: user.id))
      end.to change(user.articles, :count).by(10)
    end

    it "converts/replaces <picture> tags to <img>", vcr: { cassette_name: "rss_reader_swimburger" } do
      user = create(:user, feed_url: "https://swimburger.net/atom.xml")

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
end
