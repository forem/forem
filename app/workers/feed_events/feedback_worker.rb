module FeedEvents
  class FeedbackWorker
    include Sidekiq::Job
    sidekiq_options queue: :low_priority, retry: 10, lock: :until_executing, on_conflict: :replace

    # One job per inserted batch; receipt-only retries enqueue no work. Identical
    # queued jobs coalesce, while existing model throttles bound counter refreshes
    # and config spawning across different batches.
    def perform(event_ids)
      events = FeedEvent.where(id: event_ids)
      FeedEvent.bulk_update_counters_by_article_id(events.distinct.pluck(:article_id).sort)
      FeedEvent.bulk_update_counters_by_feed_config_id(events.distinct.pluck(:feed_config_id).compact.sort)
      events.where.not(category: :impression).find_each(&:process_ingested_engagement)
    end
  end
end
