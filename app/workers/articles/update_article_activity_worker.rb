module Articles
  # Maintains the per-article ArticleActivity cache row by applying a single
  # event delta (page view / reaction / comment) instead of re-querying the
  # whole day. If the article has no activity row yet, one is created and a
  # full backfill from raw rows runs — this is the "upsert" referenced in the
  # design. Subsequent events then take the fast append path.
  #
  # Args:
  #   article_id : Integer
  #   event_type : "page_view" | "reaction" | "comment" | nil (nil = full recompute)
  #   action     : "create" | "destroy"
  #   payload    : Hash of attributes carried inline so destroys work even
  #                after the source row is gone. Keys vary by event_type:
  #     page_view: { iso, total, sum_read_seconds, logged_in_count, domain }
  #     reaction:  { iso, category, user_id }
  #     comment:   { iso, score }
  class UpdateArticleActivityWorker
    include Sidekiq::Job

    # Deltas are non-idempotent — applying the same job twice would
    # double-count (or, on destroy, drive totals negative). retry: false
    # accepts that a transient failure loses one event; the next full
    # recompute (lazy upsert path or manual repair) reconciles drift.
    # We use sidekiq-unique-jobs to ensure at most one job is enqueued/scheduled.
    sidekiq_options queue: :low_priority,
                    retry: false,
                    lock: :until_executing,
                    on_conflict: :replace

    class << self
      def perform_async(article_id, _event_type = nil, _action = "create", _payload = {})
        return if article_id.nil?

        # Fetch last_aggregated_at, page_views_count, and created_at in a single fast query
        article_data = Article.left_outer_joins(:article_activity)
                              .where(id: article_id)
                              .pluck(:created_at, :page_views_count, "article_activities.last_aggregated_at")
                              .first
        return if article_data.nil?

        created_at, page_views_count, last_aggregated_at = article_data

        delay = debounce_delay_for(page_views_count.to_i, created_at)

        if last_aggregated_at.nil?
          # If never aggregated, run immediately
          super(article_id)
        else
          elapsed = Time.current - last_aggregated_at
          if elapsed >= delay
            # If it has been longer than the delay, run immediately
            super(article_id)
          else
            # Schedule it for the remaining delay time
            # Since lock: :until_executing, on_conflict: :replace is active,
            # this will replace/coalesce any already scheduled job for this article.
            perform_in(delay - elapsed, article_id)
          end
        end
      end

      def debounce_delay_for(page_views, created_at)
        base_delay = if page_views >= 100_000
                       5.minutes
                     elsif page_views >= 10_000
                       1.minute
                     elsif page_views >= 1_000
                       30.seconds
                     else
                       10.seconds
                     end

        return base_delay if created_at.nil?

        # Exponential decay/backoff based on age (up to 30 days to avoid float overflow)
        days_old = [[(Time.current - created_at) / 1.day, 0].max, 30].min
        calculated_delay = base_delay * (1.5**days_old)

        [calculated_delay, 30.minutes].min
      end
    end

    def perform(article_id, _event_type = nil, _action = "create", _payload = {})
      return if article_id.nil?

      activity = ArticleActivity.find_by(article_id: article_id)

      if activity.nil?
        return unless Article.exists?(id: article_id)

        activity = ArticleActivity.find_or_create_by!(article_id: article_id)
        activity.recompute_all! if activity.previously_new_record?
        return
      end

      # Always recompute on execution so legacy queued jobs with delta-style
      # args converge with newer article_id-only jobs. This avoids drift when
      # an older non-idempotent delta job runs after a recompute/coalesced job.
      activity.recompute_all!
    end
  end
end
