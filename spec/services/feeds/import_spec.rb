require "rails_helper"

RSpec.describe Feeds::Import, :vcr, type: :service do
  let(:link) { "https://medium.com/feed/@vaidehijoshi" }
  let(:nonmedium_link) { "https://circleci.com/blog/feed.xml" }
  let(:nonpermanent_link) { "https://medium.com/feed/@macsiri/" }

  before do
    allow(Feeds::ValidateUrl).to receive(:call).and_return(true)

    [link, nonmedium_link, nonpermanent_link].each do |feed_url|
      user = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)
      create(:feed_source, user: user, feed_url: feed_url)
    end
  end

  describe ".call" do
    it "filters to users with recent article or presence activity" do
      recent_article_user = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)
      create(:feed_source, user: recent_article_user, feed_url: link)
      recent_present_user = create(:user, last_presence_at: 2.weeks.ago)
      create(:feed_source, user: recent_present_user, feed_url: link)
      stale_user = create(:user, last_article_at: 6.months.ago, last_presence_at: 6.months.ago)
      create(:feed_source, user: stale_user, feed_url: link)
      no_source_user = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)

      scoped_users = User.where(id: [recent_article_user.id, recent_present_user.id, stale_user.id, no_source_user.id])
      importer = described_class.new(users_scope: scoped_users)
      filtered = importer.__send__(:filter_feed_sources, users_scope: scoped_users, earlier_than: nil)

      expect(filtered.pluck(:user_id)).to contain_exactly(recent_article_user.id, recent_present_user.id)
    end

    it "ensures that we only fetch users who can create articles", vcr: { cassette_name: "feeds_import" } do
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
      end.to change(Feeds::Source.find_by(feed_url: nonpermanent_link).user.articles, :count).by(1)
    end

    it "sets feed_fetched_at to the current time", vcr: { cassette_name: "feeds_import" } do
      Timecop.freeze(Time.current) do
        described_class.call

        user = Feeds::Source.find_by(feed_url: nonpermanent_link).user
        feed_fetched_at = user.feed_fetched_at
        expect(feed_fetched_at.to_i).to eq(Time.current.to_i)
      end
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

      it "retries on transient network errors then succeeds" do
        call_count = 0
        response_class = Class.new do
          attr_reader :body

          def initialize(body)
            @body = body
          end
        end
        allow(HTTParty).to receive(:get).and_wrap_original do |_method, *_args, **_kwargs|
          call_count += 1
          raise Net::OpenTimeout if call_count == 1

          # Return a minimal valid RSS response on retry
          response_class.new(<<~XML)
            <?xml version="1.0"?>
            <rss version="2.0"><channel><title>Test</title></channel></rss>
          XML
        end
        allow_any_instance_of(described_class).to receive(:sleep) # rubocop:disable RSpec/AnyInstance

        source = Feeds::Source.first
        described_class.call(users_scope: User.where(id: source.user_id))

        expect(call_count).to be >= 2
      end

      it "gives up after max retries on persistent timeouts" do
        allow(HTTParty).to receive(:get).and_raise(Net::ReadTimeout)
        allow(Rails.logger).to receive(:error)
        allow_any_instance_of(described_class).to receive(:sleep) # rubocop:disable RSpec/AnyInstance

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
        source = Feeds::Source.find_by(feed_url: link)
        num_articles = described_class.call(
          users_scope: User.where(id: source.user_id),
        )

        expect(num_articles).to eq(10)
      end

      it "imports no articles if given users are without feed" do
        user = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)

        expect(described_class.call(users_scope: User.where(id: user.id))).to eq(0)
      end
    end
  end

  context "when refetching" do
    it "does refetch same user over and over by default", vcr: { cassette_name: "feeds_import_multiple_times" } do
      source = Feeds::Source.find_by(feed_url: nonpermanent_link)
      user = source.user

      Timecop.freeze(Time.current) do
        user.update_columns(feed_fetched_at: Time.current)
        source.update_columns(last_fetched_at: Time.current)

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

      user = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)
      create(:feed_source, user: user, feed_url: nonpermanent_link, referential_link: false)

      described_class.call(users_scope: User.where(id: user.id))

      expect(Article).not_to have_received(:find_by)
    end
  end

  describe "feeds parsing and regressions" do
    it "parses https://medium.com/feed/@dvirsegal correctly", vcr: { cassette_name: "rss_reader_dvirsegal" } do
      user = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)
      create(:feed_source, user: user, feed_url: "https://medium.com/feed/@dvirsegal")

      expect do
        described_class.call(users_scope: User.where(id: user.id))
      end.to change(user.articles, :count).by(10)
    end

    it "converts/replaces <picture> tags to <img>", vcr: { cassette_name: "rss_reader_swimburger" } do
      user = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)
      create(:feed_source, user: user, feed_url: "https://swimburger.net/atom.xml")

      expect do
        described_class.call(users_scope: User.where(id: user.id))
      end.to change(user.articles, :count).by(10)

      body_markdown = user.articles.last.body_markdown

      expect(body_markdown).not_to include("<picture>")
      expected_image_markdown =
        "![Screenshot of Azure left navigation pane](https://swimburger.net/media/lxypkhak/azure-create-a-resource.png)"

      expect(body_markdown).to include(expected_image_markdown)
    end
  end

  context "when multiple users fetch from the same feed_url", vcr: { cassette_name: "feeds_import_two_users" } do
    it "fetches the articles in both accounts (if feed_mark_canonical = false)" do
      source1 = Feeds::Source.find_by(feed_url: link)
      rss_feed_user1 = source1.user
      rss_feed_user2 = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)
      create(:feed_source, user: rss_feed_user2, feed_url: link)
      expect do
        described_class.call(users_scope: User.where(id: Feeds::Source.where(feed_url: link).select(:user_id)))
      end
        .to change(rss_feed_user1.articles, :count).by(10)
        .and change(rss_feed_user2.articles, :count).by(10)
    end

    it "fetches the articles in both accounts (if feed_mark_canonical = true)" do
      source1 = Feeds::Source.find_by(feed_url: link)
      rss_feed_user1 = source1.user
      source1.update!(mark_canonical: true)
      rss_feed_user2 = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)
      create(:feed_source, user: rss_feed_user2, feed_url: link, mark_canonical: true)
      expect do
        described_class.call(users_scope: User.where(id: Feeds::Source.where(feed_url: link).select(:user_id)))
      end
        .to change(rss_feed_user1.articles, :count).by(10)
        .and change(rss_feed_user2.articles, :count).by(10)
    end
  end

  describe "memory and performance safeguards" do
    it "rejects oversized XML feeds exceeding MAX_XML_SIZE while streaming and records a fetch failure" do
      user = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)
      source = create(:feed_source, user: user, feed_url: "https://example.com/huge-feed.xml")
      chunk = "x" * ((described_class::MAX_XML_SIZE / 2) + 10)
      chunks_read = 0

      allow(HTTParty).to receive(:get) do |_url, **_opts, &block|
        3.times do
          chunks_read += 1
          block.call(chunk)
        end
      end
      allow(Rails.logger).to receive(:error)

      expect(described_class.call(users_scope: User.where(id: user.id))).to eq(0)
      expect(chunks_read).to eq(2)

      log = Feeds::ImportLog.where(feed_source: source).last
      expect(log).to be_present
      expect(log.status).to eq("failed")
      expect(log.error_message).to include("Feed XML exceeds maximum size")
    end

    it "truncates feeds with more than MAX_XML_ENTRIES items before parsing, including binary UTF-8 streams" do
      stub_const("#{described_class}::MAX_XML_ENTRIES", 25)
      user = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)
      source = create(:feed_source, user: user, feed_url: "https://example.com/many-items.xml")
      items_xml = (1..30).map do |idx|
        "<item><title>Post #{idx} Café</title><link>https://example.com/posts/#{idx}</link>" \
          "<description>Body #{idx}</description><pubDate>Mon, 01 Jan 2026 00:00:00 GMT</pubDate></item>"
      end.join("\n")
      xml = "<?xml version=\"1.0\"?><rss version=\"2.0\"><channel><title>Blog</title>#{items_xml}</channel></rss>".b
      fragment_class = Class.new(String) do
        def code = 200
      end
      binary_chunk = fragment_class.new(xml)

      allow(HTTParty).to receive(:get) do |_url, **_opts, &block|
        block.call(binary_chunk)
      end

      parsed_xml_arg = nil
      allow(Feedjira).to receive(:parse).and_wrap_original do |original, xml_str|
        parsed_xml_arg = xml_str
        original.call(xml_str)
      end

      imported_count = described_class.call(users_scope: User.where(id: user.id))
      expect(imported_count).to eq(described_class::MAX_ENTRIES_PER_FEED)
      expect(parsed_xml_arg.encoding).to eq(Encoding::UTF_8)
      expect(parsed_xml_arg).to include("Post 25 Café")
      expect(parsed_xml_arg).not_to include("Post 26 Café")

      log = Feeds::ImportLog.where(feed_source: source).last
      expect(log.items_in_feed).to eq(described_class::MAX_ENTRIES_PER_FEED)
      expect(log.items_imported).to eq(described_class::MAX_ENTRIES_PER_FEED)
    end

    it "selects the newest MAX_ENTRIES_PER_FEED items when a feed is ordered oldest-first (ascending)" do
      user = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)
      create(:feed_source, user: user, feed_url: "https://example.com/ascending.xml")
      base_time = Time.utc(2026, 1, 1, 12, 0, 0)
      items_xml = (1..30).map do |idx|
        pub_date = (base_time + idx.hours).rfc2822
        "<item><title>Ascending Post #{idx}</title><link>https://example.com/asc/#{idx}</link>" \
          "<description>Body #{idx}</description><pubDate>#{pub_date}</pubDate></item>"
      end.join("\n")
      xml = "<?xml version=\"1.0\"?><rss version=\"2.0\"><channel><title>Asc</title>#{items_xml}</channel></rss>"
      fragment_class = Class.new(String) do
        def code = 200
      end
      allow(HTTParty).to receive(:get).and_yield(fragment_class.new(xml.b))

      imported_count = described_class.call(users_scope: User.where(id: user.id))
      expect(imported_count).to eq(described_class::MAX_ENTRIES_PER_FEED)

      imported_titles = user.articles.pluck(:title)
      expect(imported_titles).to include("Ascending Post 30", "Ascending Post 6")
      expect(imported_titles).not_to include("Ascending Post 1", "Ascending Post 5")
    end

    it "does not spawn Parallel worker threads when importing a single feed source" do
      user = create(:user, last_article_at: 1.month.ago, last_presence_at: 1.month.ago)
      create(:feed_source, user: user, feed_url: "https://example.com/single.xml")
      xml = "<?xml version=\"1.0\"?><rss version=\"2.0\"><channel><title>Single</title></channel></rss>"
      response_double = Class.new do
        attr_reader :body

        def initialize(body)
          @body = body
        end
      end.new(xml)

      allow(HTTParty).to receive(:get).and_return(response_double)
      allow(Parallel).to receive(:map).and_call_original

      described_class.call(users_scope: User.where(id: user.id))
      expect(Parallel).not_to have_received(:map)
    end
  end
end
