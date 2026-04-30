# Per-article rolled-up analytics cache. One row per Article.
#
# Storage shape (raw counters; response shape is derived at read time so that
# worker append operations can be applied via atomic Postgres jsonb updates
# without re-querying the underlying tables):
#
#   daily_page_views[date] = { "total"=>N, "sum_read_seconds"=>N,
#                              "logged_in_count"=>N }
#   daily_reactions[date]  = { "total"=>N, "like"=>N, "readinglist"=>N,
#                              "unicorn"=>N, "exploding_head"=>N,
#                              "raised_hands"=>N, "fire"=>N,
#                              "reactor_ids"=>[user_id, ...] }
#   daily_comments[date]   = N            (count of scored comments)
#   daily_referrers[date]  = { domain => N }
class ArticleActivity < ApplicationRecord
  belongs_to :article

  REACTION_CATEGORIES = %w[like readinglist unicorn exploding_head raised_hands fire].freeze

  # ---------- READ API (response shape used by AnalyticsService) ----------

  def page_views_by_day
    daily_page_views.each_with_object({}) do |(iso, raw), out|
      out[iso] = derive_page_view_day(raw)
    end
  end

  def reactions_by_day
    daily_reactions.each_with_object({}) do |(iso, raw), out|
      out[iso] = derive_reaction_day(raw)
    end
  end

  def comments_by_day
    daily_comments.transform_values(&:to_i)
  end

  def referrers_by_day
    daily_referrers
  end

  # All-time totals derived from rolling counters and reactor_ids set.
  def page_view_totals
    sum_read = daily_page_views.values.sum { |v| v["sum_read_seconds"].to_i }
    logged = daily_page_views.values.sum { |v| v["logged_in_count"].to_i }
    avg = logged.positive? ? (sum_read.to_f / logged).round : 0
    {
      total: total_page_views,
      average_read_time_in_seconds: avg,
      total_read_time_in_seconds: total_page_views * avg
    }
  end

  def reaction_totals
    base = { total: total_reactions }
    REACTION_CATEGORIES.each { |c| base[c.to_sym] = 0 }
    reactor_set = Set.new
    daily_reactions.each_value do |raw|
      REACTION_CATEGORIES.each { |c| base[c.to_sym] += raw[c].to_i }
      Array(raw["reactor_ids"]).each { |uid| reactor_set << uid }
    end
    base[:unique_reactors] = reactor_set.size
    base
  end

  def referrer_totals(top: 20)
    counts = Hash.new(0)
    daily_referrers.each_value do |day_hash|
      day_hash.each { |domain, n| counts[domain] += n.to_i }
    end
    domains = counts.sort_by { |_, n| -n }.first(top).map { |d, n| { domain: d, count: n } }
    { domains: domains }
  end

  # ---------- WRITE API (atomic incremental appends) ----------
  #
  # All write methods accept a payload hash supplied inline by the worker so
  # that destroy/update operations work without depending on the source row.

  # payload: { iso, total, sum_read_seconds, logged_in_count, domain }
  #
  # All sub-statements run inside a single DB transaction so that a mid-write
  # error can't leave per-day counters, totals, and referrers out of sync
  # (the worker uses retry: false, so partial application would never be
  # repaired by a retry — only by a full recompute).
  def apply_page_view_delta!(payload)
    iso = payload["iso"]
    delta = {
      "total" => payload["total"].to_i,
      "sum_read_seconds" => payload["sum_read_seconds"].to_i,
      "logged_in_count" => payload["logged_in_count"].to_i
    }
    self.class.transaction do
      merge_day_counters!(:daily_page_views, iso, delta)
      bump_total!(:total_page_views, delta["total"])
      if payload["domain"].present? && delta["total"].positive?
        append_referrer!(iso, payload["domain"], delta["total"])
      end
    end
    reload
  end

  # payload: { iso, category, user_id }, sign: +1 (create) or -1 (destroy)
  def apply_reaction_delta!(payload, sign:)
    iso = payload["iso"]
    cat = payload["category"]
    delta = { "total" => sign }
    delta[cat] = sign if REACTION_CATEGORIES.include?(cat)
    self.class.transaction do
      merge_day_counters!(:daily_reactions, iso, delta)
      if sign.positive? && payload["user_id"]
        append_reactor_id!(iso, payload["user_id"].to_i)
      elsif sign.negative? && payload["user_id"]
        remove_reactor_id!(iso, payload["user_id"].to_i)
      end
      bump_total!(:total_reactions, sign)
    end
    reload
  end

  # payload: { iso }, sign: +1 (score crossed into positive) or -1 (score dropped / destroy)
  # Callers gate on score positivity; the worker just applies the supplied delta.
  def apply_comment_delta!(payload, sign:)
    iso = payload["iso"]
    return if iso.blank?

    self.class.transaction do
      bump_day_int!(:daily_comments, iso, sign)
      bump_total!(:total_comments, sign)
    end
    reload
  end

  # ---------- BACKFILL ----------

  # Rebuilds every JSONB column from raw rows. Used the first time we see an
  # article (lazy upsert) and as a manual repair tool.
  def recompute_all!
    pv = build_page_views_from_raw
    rx = build_reactions_from_raw
    cm = build_comments_from_raw
    rf = build_referrers_from_raw

    update!(
      daily_page_views: pv,
      daily_reactions: rx,
      daily_comments: cm,
      daily_referrers: rf,
      total_page_views: pv.values.sum { |v| v["total"].to_i },
      total_reactions: rx.values.sum { |v| v["total"].to_i },
      total_comments: cm.values.sum(&:to_i),
      last_aggregated_at: Time.current,
    )
  end

  def derive_page_view_day(raw)
    total = raw["total"].to_i
    logged = raw["logged_in_count"].to_i
    sum_read = raw["sum_read_seconds"].to_i
    avg = logged.positive? ? (sum_read.to_f / logged).round : 0
    {
      "total" => total,
      "average_read_time_in_seconds" => avg,
      "total_read_time_in_seconds" => total * avg
    }
  end

  def derive_reaction_day(raw)
    out = REACTION_CATEGORIES.each_with_object({ "total" => raw["total"].to_i }) { |c, h| h[c] = raw[c].to_i }
    out["unique_reactors"] = Array(raw["reactor_ids"]).uniq.length
    out
  end

  private

  # Atomically merge a hash of counter deltas into daily_<column>[iso].
  # Uses a single UPDATE that constructs the full delta object via
  # jsonb_build_object and merges it in with `||`.
  def merge_day_counters!(column, iso, delta_hash)
    quoted_iso = quote(iso)
    # Quote both the JSON key (for jsonb_build_object) and the lookup key
    # via connection.quote rather than string-interpolating raw input — keeps
    # this safe even if a payload key ever contains a quote character.
    pairs = delta_hash.flat_map do |key, n|
      quoted_key = quote(key.to_s)
      [
        quoted_key,
        "to_jsonb(COALESCE((((#{column}) -> #{quoted_iso}) ->> #{quoted_key})::int, 0) + #{n.to_i})"
      ]
    end
    sql = <<~SQL
      UPDATE article_activities
      SET #{column} = jsonb_set(
        #{column},
        ARRAY[#{quoted_iso}],
        COALESCE((#{column}) -> #{quoted_iso}, '{}'::jsonb) ||
          jsonb_build_object(#{pairs.join(', ')}),
        true
      ),
      updated_at = NOW()
      WHERE id = #{id.to_i}
    SQL
    self.class.connection.exec_update(sql)
  end

  # daily_<column>[iso] is a bare integer; bump it by `delta`.
  def bump_day_int!(column, iso, delta)
    quoted_iso = quote(iso)
    sql = <<~SQL
      UPDATE article_activities
      SET #{column} = jsonb_set(
        #{column},
        ARRAY[#{quoted_iso}],
        to_jsonb(COALESCE(((#{column}) ->> #{quoted_iso})::int, 0) + #{delta.to_i}),
        true
      ),
      updated_at = NOW()
      WHERE id = #{id.to_i}
    SQL
    self.class.connection.exec_update(sql)
  end

  def append_reactor_id!(iso, user_id)
    quoted_iso = quote(iso)
    # Read prior list from the row, append, write back atomically using `||`
    # merge of a fresh day-object containing the new array.
    sql = <<~SQL
      UPDATE article_activities
      SET daily_reactions = jsonb_set(
        daily_reactions,
        ARRAY[#{quoted_iso}],
        COALESCE(daily_reactions -> #{quoted_iso}, '{}'::jsonb) ||
          jsonb_build_object(
            'reactor_ids',
            COALESCE(daily_reactions -> #{quoted_iso} -> 'reactor_ids', '[]'::jsonb)
              || to_jsonb(#{user_id.to_i})
          ),
        true
      ),
      updated_at = NOW()
      WHERE id = #{id.to_i}
    SQL
    self.class.connection.exec_update(sql)
  end

  def remove_reactor_id!(_iso, _user_id)
    # NO-OP by design. Surgically removing a single user_id from a per-day
    # reactor_ids array on reaction destroy would require knowing whether
    # that user has other reactions on the article that day — which would
    # mean re-querying, defeating the purpose of the append fast-path.
    # We accept that `unique_reactors` may very slightly overcount after a
    # reaction is destroyed; the next full recompute (manual or scheduled)
    # rebuilds it precisely.
  end

  def append_referrer!(iso, domain, count = 1)
    quoted_iso = quote(iso)
    quoted_domain = quote(domain)
    delta_int = count.to_i
    sql = <<~SQL
      UPDATE article_activities
      SET daily_referrers = jsonb_set(
        daily_referrers,
        ARRAY[#{quoted_iso}],
        COALESCE(daily_referrers -> #{quoted_iso}, '{}'::jsonb) ||
          jsonb_build_object(
            #{quoted_domain},
            to_jsonb(
              COALESCE(((daily_referrers -> #{quoted_iso}) ->> #{quoted_domain})::int, 0) + #{delta_int}
            )
          ),
        true
      ),
      updated_at = NOW()
      WHERE id = #{id.to_i}
    SQL
    self.class.connection.exec_update(sql)
  end

  def bump_total!(column, delta)
    self.class.where(id: id).update_all([
                                          "#{column} = #{column} + ?, updated_at = NOW()",
                                          delta.to_i
                                        ])
  end

  def quote(val)
    self.class.connection.quote(val)
  end

  # --- backfill builders ---

  def build_page_views_from_raw
    PageView.where(article_id: article_id)
      .group("DATE(created_at)")
      .pluck(
        Arel.sql("DATE(created_at)"),
        Arel.sql("COALESCE(SUM(counts_for_number_of_views), 0)"),
        Arel.sql("COALESCE(SUM(time_tracked_in_seconds) FILTER (WHERE user_id IS NOT NULL), 0)"),
        Arel.sql("COUNT(*) FILTER (WHERE user_id IS NOT NULL)"),
      ).each_with_object({}) do |(date, total, sum_read, logged), hash|
        hash[date.iso8601] = {
          "total" => total.to_i,
          "sum_read_seconds" => sum_read.to_i,
          "logged_in_count" => logged.to_i
        }
      end
  end

  def build_reactions_from_raw
    # Aggregate per-day category counts AND distinct reactor ids in a single
    # grouped query. Previously we plucked one Ruby row per reaction to build
    # the reactor_ids array client-side, which got expensive on hot articles;
    # array_agg(DISTINCT ...) keeps the materialization in Postgres.
    Reaction.for_analytics
      .where(reactable_id: article_id, reactable_type: "Article")
      .group("DATE(created_at)")
      .pluck(
        Arel.sql("DATE(created_at)"),
        Arel.sql("COUNT(*)"),
        Arel.sql("COUNT(*) FILTER (WHERE category = 'like')"),
        Arel.sql("COUNT(*) FILTER (WHERE category = 'readinglist')"),
        Arel.sql("COUNT(*) FILTER (WHERE category = 'unicorn')"),
        Arel.sql("COUNT(*) FILTER (WHERE category = 'exploding_head')"),
        Arel.sql("COUNT(*) FILTER (WHERE category = 'raised_hands')"),
        Arel.sql("COUNT(*) FILTER (WHERE category = 'fire')"),
        Arel.sql("COALESCE(array_agg(DISTINCT user_id) FILTER (WHERE user_id IS NOT NULL), '{}')"),
      ).each_with_object({}) do |row, hash|
        date, total, like, rl, uni, eh, rh, fire, reactor_ids = row
        hash[date.iso8601] = {
          "total" => total.to_i, "like" => like.to_i, "readinglist" => rl.to_i,
          "unicorn" => uni.to_i, "exploding_head" => eh.to_i,
          "raised_hands" => rh.to_i, "fire" => fire.to_i,
          "reactor_ids" => Array(reactor_ids).map(&:to_i)
        }
      end
  end

  def build_comments_from_raw
    Comment.where(commentable_id: article_id, commentable_type: "Article")
      .where("score > 0")
      .group("DATE(created_at)").count.transform_keys(&:iso8601)
  end

  def build_referrers_from_raw
    PageView.where(article_id: article_id)
      .where.not(domain: [nil, ""])
      .group("DATE(created_at)", :domain)
      .sum(:counts_for_number_of_views)
      .each_with_object({}) do |((date, domain), n), hash|
        iso = date.iso8601
        hash[iso] ||= {}
        hash[iso][domain] = n.to_i
      end
  end
end
