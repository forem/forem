class CreateArticleActivities < ActiveRecord::Migration[7.0]
  def change
    create_table :article_activities do |t|
      t.references :article, null: false, foreign_key: true, index: { unique: true }

      # Per-day buckets keyed by ISO date string ("YYYY-MM-DD"). Storage shape
      # holds raw counters (not the response shape) so that worker append
      # operations can be applied via atomic Postgres jsonb_set updates without
      # re-querying the underlying tables.
      #
      # daily_page_views[date] = { total, sum_read_seconds, logged_in_count }
      # daily_reactions[date]  = { total, like, readinglist, unicorn,
      #                            exploding_head, raised_hands, fire,
      #                            reactor_ids: [user_id, ...] }
      # daily_comments[date]   = integer (count of scored comments)
      # daily_referrers[date]  = { domain => count }
      t.jsonb :daily_page_views, null: false, default: {}
      t.jsonb :daily_reactions,  null: false, default: {}
      t.jsonb :daily_comments,   null: false, default: {}
      t.jsonb :daily_referrers,  null: false, default: {}

      # Rolling all-time totals; cheap path for cards that don't need per-day.
      t.integer :total_page_views, null: false, default: 0
      t.integer :total_reactions,  null: false, default: 0
      t.integer :total_comments,   null: false, default: 0

      # When the row was last fully recomputed (vs only incremental updates).
      t.datetime :last_aggregated_at

      t.timestamps
    end
  end
end
