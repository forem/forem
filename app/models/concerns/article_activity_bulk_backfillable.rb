module ArticleActivityBulkBackfillable
  extend ActiveSupport::Concern

  module ClassMethods
    def bulk_backfill!(article_ids)
      ids = Article.where(id: article_ids).ids
      return if ids.empty?

      aggregates = ids.index_with do
        {
          daily_page_views: {}, daily_reactions: {}, daily_comments: {}, daily_referrers: {},
          total_page_views: 0, total_reactions: 0, total_comments: 0
        }
      end

      aggregate_page_views(ids, aggregates)
      aggregate_reactions(ids, aggregates)
      aggregate_comments(ids, aggregates)

      now = Time.current
      rows = aggregates.map do |article_id, values|
        values.merge(article_id: article_id, last_aggregated_at: now, created_at: now, updated_at: now)
      end
      insert_all(rows, unique_by: :index_article_activities_on_article_id)
    end

    private

    def aggregate_page_views(ids, aggregates)
      PageView.where(article_id: ids)
        .group(:article_id, "DATE(created_at)", :domain)
        .pluck(
          :article_id,
          Arel.sql("DATE(created_at)"),
          :domain,
          Arel.sql("COALESCE(SUM(counts_for_number_of_views), 0)"),
          Arel.sql("COALESCE(SUM(time_tracked_in_seconds) FILTER (WHERE user_id IS NOT NULL), 0)"),
          Arel.sql("COUNT(*) FILTER (WHERE user_id IS NOT NULL)"),
        ).each do |article_id, date, domain, total, sum_read, logged|
          iso = date.iso8601
          day = aggregates.fetch(article_id)[:daily_page_views]
            .fetch(iso, { "total" => 0, "sum_read_seconds" => 0, "logged_in_count" => 0 })
          day["total"] += total.to_i
          day["sum_read_seconds"] += sum_read.to_i
          day["logged_in_count"] += logged.to_i
          aggregates.fetch(article_id)[:daily_page_views][iso] = day
          aggregates.fetch(article_id)[:daily_referrers][iso] ||= {}
          aggregates.fetch(article_id)[:daily_referrers][iso][domain.to_s] = total.to_i
          aggregates.fetch(article_id)[:total_page_views] += total.to_i
        end
    end

    def aggregate_reactions(ids, aggregates)
      Reaction.for_analytics
        .where(reactable_id: ids, reactable_type: "Article")
        .group(:reactable_id, "DATE(created_at)")
        .pluck(
          :reactable_id,
          Arel.sql("DATE(created_at)"),
          Arel.sql("COUNT(*)"),
          *self::REACTION_CATEGORIES.map { |category| Arel.sql("COUNT(*) FILTER (WHERE category = '#{category}')") },
          Arel.sql("COALESCE(array_agg(DISTINCT user_id) FILTER (WHERE user_id IS NOT NULL), '{}')"),
        ).each do |row|
          article_id, date, total, *counts, reactor_ids = row
          values = { "total" => total.to_i, "reactor_ids" => Array(reactor_ids).map(&:to_i) }
          self::REACTION_CATEGORIES.zip(counts) { |category, count| values[category] = count.to_i }
          aggregates.fetch(article_id)[:daily_reactions][date.iso8601] = values
          aggregates.fetch(article_id)[:total_reactions] += total.to_i
        end
    end

    def aggregate_comments(ids, aggregates)
      Comment.where(commentable_id: ids, commentable_type: "Article")
        .where("score > 0")
        .group(:commentable_id, "DATE(created_at)")
        .count.each do |(article_id, date), total|
          aggregates.fetch(article_id)[:daily_comments][date.iso8601] = total
          aggregates.fetch(article_id)[:total_comments] += total
        end
    end
  end
end
