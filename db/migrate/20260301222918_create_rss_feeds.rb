class CreateRssFeeds < ActiveRecord::Migration[7.0]
  def up
    create_table :rss_feeds do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :url, null: false
      t.references :fallback_organization, null: true, foreign_key: { to_table: :organizations, on_delete: :nullify }
      t.references :fallback_user, null: true, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :last_fetched_at
      t.boolean :mark_canonical, default: false, null: false
      t.boolean :referential_link, default: true, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :rss_feeds, :url

    safety_assured {
      execute <<-SQL
        INSERT INTO rss_feeds (user_id, url, mark_canonical, referential_link, last_fetched_at, created_at, updated_at)
        SELECT us.user_id, us.feed_url, us.feed_mark_canonical, us.feed_referential_link, u.feed_fetched_at, NOW(), NOW()
        FROM users_settings us
        JOIN users u ON u.id = us.user_id
        WHERE us.feed_url IS NOT NULL AND us.feed_url != '';
      SQL
    }

    create_table :rss_feed_imports do |t|
      t.references :rss_feed, null: false, foreign_key: { on_delete: :cascade }
      t.integer :status, default: 0, null: false
      t.integer :articles_found, default: 0, null: false
      t.integer :articles_imported, default: 0, null: false
      t.text :error_message

      t.timestamps
    end

    create_table :rss_feed_imported_articles do |t|
      t.references :rss_feed_import, null: false, foreign_key: { on_delete: :cascade }
      t.string :source_url, null: false
      t.string :title
      t.integer :status, default: 0, null: false
      t.references :article, null: true, foreign_key: { on_delete: :nullify }
      t.text :error_message

      t.timestamps
    end

    add_index :rss_feed_imported_articles, :source_url

    safety_assured {
      remove_column :users, :feed_fetched_at
      remove_column :users_settings, :feed_mark_canonical
      remove_column :users_settings, :feed_referential_link
      remove_column :users_settings, :feed_url
    }
  end

  def down
    add_column :users, :feed_fetched_at, :datetime
    add_column :users_settings, :feed_url, :string
    add_column :users_settings, :feed_mark_canonical, :boolean, default: false
    add_column :users_settings, :feed_referential_link, :boolean, default: true

    safety_assured {
      execute <<-SQL
        UPDATE users_settings us
        SET feed_url = rf.url,
            feed_mark_canonical = rf.mark_canonical,
            feed_referential_link = rf.referential_link
        FROM rss_feeds rf
        WHERE rf.user_id = us.user_id;
      SQL

      execute <<-SQL
        UPDATE users u
        SET feed_fetched_at = rf.last_fetched_at
        FROM rss_feeds rf
        WHERE rf.user_id = u.id;
      SQL
    }

    drop_table :rss_feed_imported_articles
    drop_table :rss_feed_imports
    drop_table :rss_feeds
  end
end
