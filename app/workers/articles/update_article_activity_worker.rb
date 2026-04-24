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

    sidekiq_options queue: :low_priority, retry: 10

    def perform(article_id, event_type = nil, action = "create", payload = {})
      return if article_id.nil?

      activity = ArticleActivity.find_by(article_id: article_id)

      if activity.nil?
        return unless Article.exists?(id: article_id)

        activity = ArticleActivity.create!(article_id: article_id)
        activity.recompute_all!
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
