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
    sidekiq_options queue: :low_priority, retry: false

    def perform(article_id, event_type = nil, action = "create", payload = {})
      return if article_id.nil?

      activity = ArticleActivity.find_by(article_id: article_id)

      if activity.nil?
        return unless Article.exists?(id: article_id)

        # find_or_create_by! handles the race where two near-simultaneous
        # events for the same article try to create the row at the same
        # moment (the article_id unique index would otherwise raise
        # RecordNotUnique and, with retry: false, drop one event entirely).
        # We only run a full recompute when *we* won the create; the loser
        # returns and lets the recompute the winner is about to do cover
        # both source rows.
        activity = ArticleActivity.find_or_create_by!(article_id: article_id)
        activity.recompute_all! if activity.previously_new_record?
        return
      end

      return activity.recompute_all! if event_type.nil?

      apply_event(activity, event_type, action, (payload || {}).with_indifferent_access)
    end

    private

    def apply_event(activity, event_type, action, payload)
      case event_type
      when "page_view"
        activity.apply_page_view_delta!(payload) if action == "create"
      when "reaction"
        if action == "destroy"
          activity.apply_reaction_delta!(payload, sign: -1)
        else
          activity.apply_reaction_delta!(payload, sign: +1)
        end
      when "comment"
        if action == "destroy"
          activity.apply_comment_delta!(payload, sign: -1)
        else
          activity.apply_comment_delta!(payload, sign: +1)
        end
      end
    end
  end
end
