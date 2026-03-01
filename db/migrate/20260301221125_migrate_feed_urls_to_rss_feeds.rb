class MigrateFeedUrlsToRssFeeds < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
      execute <<~SQL.squish
        INSERT INTO rss_feeds (user_id, feed_url, mark_canonical, referential_link, last_fetched_at, status, created_at, updated_at)
        SELECT us.user_id,
               us.feed_url,
               COALESCE(us.feed_mark_canonical, false),
               COALESCE(us.feed_referential_link, true),
               u.feed_fetched_at,
               0,
               NOW(),
               NOW()
        FROM users_settings us
        INNER JOIN users u ON u.id = us.user_id
        WHERE us.feed_url IS NOT NULL AND us.feed_url != ''
          ON CONFLICT DO NOTHING
      SQL
    end
  end

  def down
    # Data migration — no rollback needed; old columns are still in place
  end
end
