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

    class << self
      def perform_async(article_id, event_type = nil, action = "create", payload = {})
        return if article_id.nil?

        delay = debounce_delay_for(article_id)

        Sidekiq.redis do |redis|
          redis.rpush("article_activity_debounce:#{article_id}", {
            event_type: event_type,
            action: action,
            payload: payload
          }.to_json)

          lock_key = "article_activity_debounce_scheduled:#{article_id}"
          lock_expiry = [delay.to_i * 2, 60].max
          locked = redis.set(lock_key, 1, nx: true, ex: lock_expiry)
          if locked
            perform_in(delay, article_id)
          end
        end
      end

      def debounce_delay_for(article_id)
        # Pluck only page_views_count using indexed primary key lookup
        page_views = Article.where(id: article_id).pluck(:page_views_count).first.to_i

        if page_views >= 100_000
          5.minutes
        elsif page_views >= 10_000
          1.minute
        elsif page_views >= 1_000
          30.seconds
        else
          10.seconds
        end
      end
    end

    def perform(article_id, event_type = nil, action = "create", payload = {})
      return if article_id.nil?

      if event_type.present?
        # Direct/non-debounced call (e.g. from tests or old queue items)
        activity = find_or_create_activity(article_id)
        return unless activity

        apply_event(activity, event_type, action, (payload || {}).with_indifferent_access)
      else
        # Debounced run or full recompute (event_type is nil)
        events_json = Sidekiq.redis do |redis|
          res = redis.multi do |multi|
            multi.lrange("article_activity_debounce:#{article_id}", 0, -1)
            multi.del("article_activity_debounce:#{article_id}")
            multi.del("article_activity_debounce_scheduled:#{article_id}")
          end
          res[0]
        end

        if events_json.present?
          process_debounced_events(article_id, events_json)
        else
          # Fallback to full recompute
          activity = find_or_create_activity(article_id)
          return unless activity

          activity.recompute_all!
        end
      end
    end

    private

    def find_or_create_activity(article_id)
      activity = ArticleActivity.find_by(article_id: article_id)

      if activity.nil?
        return nil unless Article.exists?(id: article_id)

        activity = ArticleActivity.find_or_create_by!(article_id: article_id)
        activity.recompute_all! if activity.previously_new_record?
        return nil
      end

      activity
    end

    def process_debounced_events(article_id, events_json)
      events = events_json.map { |j| JSON.parse(j) rescue nil }.compact

      # If any event in the list represents a full recompute, do it and stop.
      if events.any? { |e| e["event_type"].nil? }
        activity = find_or_create_activity(article_id)
        activity&.recompute_all!
        return
      end

      activity = find_or_create_activity(article_id)
      return unless activity

      # Separate page views from other events (reactions, comments)
      page_views = []
      other_events = []

      events.each do |event|
        if event["event_type"] == "page_view"
          page_views << event
        else
          other_events << event
        end
      end

      # Process aggregated page views
      if page_views.present?
        # Group by iso and domain to sum up counters
        grouped_pvs = Hash.new { |h, k| h[k] = Hash.new { |h2, k2| h2[k2] = { "total" => 0, "sum_read_seconds" => 0, "logged_in_count" => 0 } } }

        page_views.each do |pv|
          payload = pv["payload"] || {}
          iso = payload["iso"]
          domain = payload["domain"] || ""

          next if iso.blank?

          grouped_pvs[iso][domain]["total"] += (payload["total"] || 0).to_i
          grouped_pvs[iso][domain]["sum_read_seconds"] += (payload["sum_read_seconds"] || 0).to_i
          grouped_pvs[iso][domain]["logged_in_count"] += (payload["logged_in_count"] || 0).to_i
        end

        grouped_pvs.each do |iso, domains|
          domains.each do |domain, data|
            next if data["total"] <= 0

            payload = {
              "iso" => iso,
              "domain" => domain.presence,
              "total" => data["total"],
              "sum_read_seconds" => data["sum_read_seconds"],
              "logged_in_count" => data["logged_in_count"]
            }
            activity.apply_page_view_delta!(payload)
          end
        end
      end

      # Process other events sequentially
      other_events.each do |event|
        apply_event(activity, event["event_type"], event["action"], (event["payload"] || {}).with_indifferent_access)
      end
    end

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
