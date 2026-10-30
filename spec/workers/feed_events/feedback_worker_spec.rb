require "rails_helper"

RSpec.describe FeedEvents::FeedbackWorker do
  it "keeps accepted events durable when a counter refresh fails and retries feedback separately" do
    event = create(:feed_event)
    allow(FeedEvent).to receive(:bulk_update_counters_by_article_id).and_raise(ActiveRecord::QueryCanceled)
    expect { described_class.new.perform([event.id]) }.to raise_error(ActiveRecord::QueryCanceled)
    expect(FeedEvent.exists?(event.id)).to be(true)
    expect(described_class.get_sidekiq_options).to include("retry" => 10, "lock" => :until_executing)
  end

  it "refreshes config maturity before spawning from freshly stored engagement" do
    article = create(:article)
    user = create(:user)
    config = create(:feed_config)
    impression = { article_id: article.id, user_id: user.id, feed_config_id: config.id,
                   category: "impression", context_type: "email", article_position: 1 }
    rows = Array.new(FeedConfig::LOW_IMPRESSION_COUNT) { impression }
    rows << impression.merge(category: "click")
    ids = FeedEvent.insert_all(rows, returning: %w[id]).pluck("id")
    expect(config.feed_impressions_count).to eq(0)
    expect { described_class.new.perform(ids) }.to change(FeedConfig, :count).by(1)
    expect(config.reload.feed_impressions_count).to eq(FeedConfig::LOW_IMPRESSION_COUNT)
    expect(FeedConfig.last.targeting_bucket).to eq(FeedConfig::BUCKET_DIGEST)
  end

  it "ignores events removed before the job executes" do
    expect { described_class.new.perform([0]) }.not_to raise_error
  end
end
