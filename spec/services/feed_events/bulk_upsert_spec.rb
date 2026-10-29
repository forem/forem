require "rails_helper"

RSpec.describe FeedEvents::BulkUpsert, type: :service do
  let(:user) { create(:user) }
  let(:second_user) { create(:user) }

  def feed_event(**attributes)
    build(:feed_event, **attributes).attributes
  end

  context "when there are no duplicates in the list or database" do
    let(:articles) { create_list(:article, 5) }
    let(:feed_events_data) do
      articles
        .map
        .with_index do |article, index|
          {
            article: article,
            user: user,
            article_position: index + 1,
            category: :impression,
            context_type: FeedEvent::CONTEXT_TYPE_HOME
          }
        end
    end

    it "inserts all the feed events" do
      expect { described_class.call(feed_events_data) }.to change(FeedEvent, :count).by(5)
      expect(FeedEvent.pluck(:article_id, :user_id, :category)).to match_array(
        articles.map { |article| [article.id, user.id, "impression"] },
      )
    end

    it "calls bulk_update_counters_by_article_id for article ids" do
      allow(FeedEvent).to receive(:bulk_update_counters_by_article_id)
      described_class.call(feed_events_data)
      expect(FeedEvent).to have_received(:bulk_update_counters_by_article_id).with(match_array(articles.map(&:id)))
    end

    it "calls bulk_update_counters_by_feed_config_id for feed_config_ids" do
      feed_config = create(:feed_config)
      events_with_config = feed_events_data.map { |event| event.merge(feed_config_id: feed_config.id) }
      allow(FeedEvent).to receive(:bulk_update_counters_by_feed_config_id)

      described_class.call(events_with_config)

      expect(FeedEvent).to have_received(:bulk_update_counters_by_feed_config_id).with(
        Array.new(articles.size, feed_config.id),
      )
    end
  end

  context "when there are more than 5 events" do
    let(:articles) { create_list(:article, 8) }
    let(:feed_events_data) do
      articles
        .map
        .with_index do |article, index|
          {
            article: article,
            user: user,
            article_position: index + 1,
            category: :impression,
            context_type: FeedEvent::CONTEXT_TYPE_HOME
          }
        end
    end

    it "calls bulk_update_counters_by_article_id for article ids" do
      allow(FeedEvent).to receive(:bulk_update_counters_by_article_id)
      described_class.call(feed_events_data)
      expect(FeedEvent).to have_received(:bulk_update_counters_by_article_id).with(satisfy do |arg|
                                                                                     arg.is_a?(Array) && arg.length == 8
                                                                                   end)
    end
  end

  context "when there are duplicate events within the list" do
    let(:article) { create(:article) }
    let(:feed_events_data) do
      Array.new(5) do
        feed_event(article: article, user: user, category: :click)
      end
    end

    it "does not insert extra duplicate events" do
      expect { described_class.call(feed_events_data) }.to change(FeedEvent, :count).by(1)
      expect(FeedEvent.pluck(:article_id, :user_id, :category)).to contain_exactly(
        [article.id, user.id, "click"],
      )
    end
  end

  context "when there are invalid events in the list" do
    let(:article) { create(:article) }
    let(:feed_events_data) do
      [
        feed_event(article: nil, user: user, category: :click),
        feed_event(article: article, user: user).merge(category: :not_a_real_category),
        feed_event(article: article, user: user, category: :impression),
        feed_event(article: article, user: nil, category: :impression),
        feed_event(article: article, user: second_user, category: :impression, context_type: "blahblahblah"),
        feed_event(article: article, user: second_user, category: :click, article_position: -2),
      ]
    end

    it "filters them out" do
      expect { described_class.call(feed_events_data, timebox: nil) }.to change(FeedEvent, :count).by(2)
      expect(FeedEvent.pluck(:article_id, :user_id, :category)).to contain_exactly(
        [article.id, user.id, "impression"],
        [article.id, nil, "impression"],
      )
    end
  end

  context "when there is only one valid item in the list" do
    let(:article) { create(:article) }
    let(:feed_config) { create(:feed_config) }
    let(:feed_event_data) do
      [
        feed_event(article: article, user: user, category: :click, context_type: "foobar"),
        feed_event(article: article, user: second_user, category: :impression, feed_config_id: feed_config.id),
      ]
    end

    it "handles it appropriately and preserves feed_config_id" do
      expect { described_class.call(feed_event_data) }.to change(FeedEvent, :count).by(1)
      expect(FeedEvent.pluck(:article_id, :user_id, :category, :feed_config_id)).to contain_exactly(
        [article.id, second_user.id, "impression", feed_config.id],
      )
    end
  end

  context "when there are no valid items in the list" do
    let(:feed_event_data) do
      [
        feed_event(article: nil, user: user, category: :click),
        feed_event(article: nil, user: second_user, category: :click),
      ]
    end

    it "does nothing and returns" do
      allow(FeedEvent).to receive(:where).and_call_original

      expect { described_class.call(feed_event_data) }.not_to change(FeedEvent, :count)

      expect(FeedEvent).not_to have_received(:where)
    end
  end

  context "when events reference deleted articles or users" do
    let(:article) { create(:article) }
    let(:deleted_article) { create(:article) }
    let(:deleted_user) { create(:user) }

    let(:feed_events_data) do
      [
        feed_event(article_id: article.id, user_id: user.id, category: :impression),
        feed_event(article_id: deleted_article.id, user_id: user.id, category: :impression),
        feed_event(article_id: article.id, user_id: deleted_user.id, category: :impression),
      ]
    end

    before do
      deleted_article.destroy
      deleted_user.destroy
    end

    it "filters them out to prevent foreign key violations" do
      expect { described_class.call(feed_events_data, timebox: nil) }.to change(FeedEvent, :count).by(1)
      expect(FeedEvent.pluck(:article_id, :user_id, :category)).to contain_exactly(
        [article.id, user.id, "impression"],
      )
    end
  end

  context "with one event" do
    let(:article) { create(:article) }
    let(:data) { [feed_event(article: article, user: user, category: :impression)] }

    it "suppresses an existing impression within the window" do
      create(:feed_event, article: article, user: user, category: :impression)
      expect { described_class.call(data) }.not_to change(FeedEvent, :count)
    end

    it "records a new impression after the window" do
      create(:feed_event, article: article, user: user, category: :impression, created_at: 6.minutes.ago)
      expect { described_class.call(data) }.to change(FeedEvent, :count).by(1)
    end

    it "supports disabling the timebox" do
      create(:feed_event, article: article, user: user, category: :impression)
      expect { described_class.call(data, timebox: nil) }.to change(FeedEvent, :count).by(1)
    end

    it "does not allow another context to suppress a home impression" do
      create(:feed_event, article: article, user: user, category: :impression, context_type: "sidebar")
      expect { described_class.call(data) }.to change(FeedEvent, :count).by(1)
    end

    it "attributes a new exposure to a different config within the same surface" do
      first_config = create(:feed_config)
      second_config = create(:feed_config)
      create(:feed_event, article: article, user: user, feed_config: first_config)
      data.first["feed_config_id"] = second_config.id
      expect { described_class.call(data) }.to change(FeedEvent, :count).by(1)
      expect(second_config.reload.feed_impressions_count).to eq(1)
    end

    it "keeps accepted event IDs idempotent beyond the timebox" do
      data.first["event_id"] = SecureRandom.uuid
      described_class.call(data)
      Timecop.travel(6.minutes.from_now) do
        expect { described_class.call(data) }.not_to change(FeedEvent, :count)
      end
    end

    it "remembers a suppressed event ID after the timebox expires" do
      create(:feed_event, article: article, user: user, category: :impression)
      data.first["event_id"] = SecureRandom.uuid
      expect { described_class.call(data) }.not_to change(FeedEvent, :count)
      Timecop.travel(6.minutes.from_now) do
        expect { described_class.call(data) }.not_to change(FeedEvent, :count)
      end
    end

    it "rolls back the delivery receipt when storing the event fails" do
      data.first["event_id"] = SecureRandom.uuid
      allow(FeedEvent).to receive(:create!).and_raise(ActiveRecord::StatementInvalid)
      expect { described_class.call(data) }.to raise_error(ActiveRecord::StatementInvalid)
      expect(FeedEventReceipt.exists?(id: data.first["event_id"])).to be(false)
      allow(FeedEvent).to receive(:create!).and_call_original
      expect { described_class.call(data) }.to change(FeedEvent, :count).by(1)
    end

    it "retries a foreign-key race instead of acknowledging a lost event" do
      attempts = 0
      allow(FeedEvent).to receive(:create!).and_wrap_original do |original, *args|
        attempts += 1
        raise ActiveRecord::InvalidForeignKey if attempts == 1

        original.call(*args)
      end
      expect { described_class.call(data) }.to change(FeedEvent, :count).by(1)
    end
  end

  it "preserves impressions from different contexts within the same batch" do
    article = create(:article)
    events = %w[home sidebar].map do |context|
      feed_event(article: article, user: user, category: :impression, context_type: context)
    end
    expect { described_class.call(events) }.to change(FeedEvent, :count).by(2)
  end

  it "deduplicates retried multi-event batches after the timebox" do
    events = create_list(:article, 2).map do |article|
      feed_event(article: article, user: user, category: :impression, event_id: SecureRandom.uuid)
    end
    described_class.call(events)
    Timecop.travel(6.minutes.from_now) do
      expect { described_class.call(events) }.not_to change(FeedEvent, :count)
    end
  end

  context "when there are already existing events with the same article, user and category" do
    let(:article) { create(:article) }
    let(:second_article) { create(:article) }
    let(:feed_events_data) do
      [
        feed_event(article: article, user: user, category: :impression),
        feed_event(article: article, user: user, category: :click),
        feed_event(article: article, user: second_user, category: :impression),
        feed_event(article: second_article, user: user, category: :impression),
      ]
    end

    before do
      create(:feed_event, article: article, user: user, category: :impression)
      create(:feed_event, article: article, user: second_user, category: :impression)
    end

    it "ignores them if no timebox is provided" do
      expect { described_class.call(feed_events_data, timebox: nil) }.to change(FeedEvent, :count).by(4)
      expect(FeedEvent.pluck(:article_id, :user_id, :category)).to contain_exactly(
        [article.id, user.id, "impression"],
        [article.id, second_user.id, "impression"],
        [article.id, user.id, "impression"],
        [article.id, user.id, "click"],
        [article.id, second_user.id, "impression"],
        [second_article.id, user.id, "impression"],
      )
    end

    it "does not create new events if the existing matching events were created within the provided timebox" do
      Timecop.travel(7.minutes.from_now) do
        expect { described_class.call(feed_events_data, timebox: 10.minutes) }.to change(FeedEvent, :count).by(2)
        expect(FeedEvent.pluck(:article_id, :user_id, :category)).to contain_exactly(
          [article.id, user.id, "impression"],
          [article.id, second_user.id, "impression"],
          [article.id, user.id, "click"],
          [second_article.id, user.id, "impression"],
        )
      end
    end

    it "creates new events if the existing matching events were created outside the provided timebox" do
      Timecop.travel(12.minutes.from_now) do
        expect { described_class.call(feed_events_data, timebox: 10.minutes) }.to change(FeedEvent, :count).by(4)
        expect(FeedEvent.pluck(:article_id, :user_id, :category)).to contain_exactly(
          [article.id, user.id, "impression"],
          [article.id, second_user.id, "impression"],
          [article.id, user.id, "impression"],
          [article.id, user.id, "click"],
          [article.id, second_user.id, "impression"],
          [second_article.id, user.id, "impression"],
        )
      end
    end
  end

  context "with feed config feedback", :throttled_call do
    it "spawns from batched engagement after recording the exposure that proves a config" do
      article = create(:article)
      config = create(:feed_config, feed_impressions_count: FeedConfig::LOW_IMPRESSION_COUNT - 1)
      attributes = { article_id: article.id, user_id: user.id, category: "impression",
                     context_type: "email", feed_config_id: config.id, article_position: 1,
                     created_at: 6.minutes.ago, updated_at: 6.minutes.ago }
      FeedEvent.insert_all(Array.new(FeedConfig::LOW_IMPRESSION_COUNT - 1) { attributes })
      events = %w[click impression].map do |category|
        attributes.except(:created_at, :updated_at).merge(category: category, event_id: SecureRandom.uuid)
      end
      expect { described_class.call(events) }.to change(FeedConfig, :count).by(1)
      expect(config.reload.feed_impressions_count).to eq(FeedConfig::LOW_IMPRESSION_COUNT)
      expect(FeedConfig.last.targeting_bucket).to eq(FeedConfig::BUCKET_DIGEST)
      Timecop.travel(6.minutes.from_now) do
        expect { described_class.call(events) }.not_to change(FeedConfig, :count)
      end
    end

    it "retains the home-click spawning restriction for mixed batches" do
      article = create(:article)
      config = create(:feed_config, feed_impressions_count: FeedConfig::LOW_IMPRESSION_COUNT)
      events = %w[impression click].map do |category|
        feed_event(article: article, user: user, feed_config: config, category: category)
      end
      expect { described_class.call(events) }.not_to change(FeedConfig, :count)
    end
  end

  context "with concurrent ingestion" do
    self.use_transactional_tests = false

    let!(:concurrent_user) { create(:user) }
    let!(:concurrent_articles) { create_list(:article, 2, user: concurrent_user, with_tags: false) }

    after do
      concurrent_articles.each(&:destroy!)
      concurrent_user.destroy!
    end

    it "suppresses duplicates across database connections" do
      # Widen the read/insert race. Without the user lock both connections would
      # see no recent events before either inserts its batch.
      service = Class.new(described_class) do
        private

        def find_existing_events_within_timebox(&block)
          super
          sleep 0.1
        end
      end
      data = concurrent_articles.map do |article|
        { article_id: article.id, user_id: concurrent_user.id, category: :impression,
          context_type: "home", article_position: 1 }
      end
      threads = Array.new(2) do
        Thread.new do
          ActiveRecord::Base.connection_pool.with_connection { service.call(data) }
        end
      end
      threads.each(&:value)
      expect(FeedEvent.where(user_id: concurrent_user.id).count).to eq(2)
    end
  end
end
