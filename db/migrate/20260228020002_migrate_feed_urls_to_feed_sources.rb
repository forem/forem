class MigrateFeedUrlsToFeedSources < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      execute <<~SQL.squish
        INSERT INTO feed_sources (user_id, feed_url, mark_canonical, referential_link,
                                  status, status_message, consecutive_failures,
                                  last_fetched_at, created_at, updated_at)
        SELECT us.user_id,
               us.feed_url,
               us.feed_mark_canonical,
               us.feed_referential_link,
               us.feed_status,
               us.feed_status_message,
               us.consecutive_feed_failures,
               u.feed_fetched_at,
               NOW(),
               NOW()
        FROM users_settings us
        INNER JOIN users u ON u.id = us.user_id
        WHERE COALESCE(us.feed_url, '') <> ''
        ON CONFLICT (user_id, feed_url) DO NOTHING
      SQL

      execute <<~SQL.squish
        UPDATE feed_import_logs
        SET feed_source_id = fs.id
        FROM feed_sources fs
        WHERE feed_import_logs.user_id = fs.user_id
          AND feed_import_logs.feed_url = fs.feed_url
          AND feed_import_logs.feed_source_id IS NULL
      SQL
    end
  end

  def down
    safety_assured do
      execute "UPDATE feed_import_logs SET feed_source_id = NULL"
      # Only delete sources that were migrated from users_settings, not ones created via the UI
      execute <<~SQL.squish
        DELETE FROM feed_sources
        WHERE (user_id, feed_url) IN (
          SELECT user_id, feed_url FROM users_settings
          WHERE COALESCE(feed_url, '') <> ''
        )
      SQL
    end
  end
end
