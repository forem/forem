class CreateRssFeeds < ActiveRecord::Migration[7.0]
  def change
    create_table :rss_feeds do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :feed_url, null: false, limit: 500
      t.string :name, limit: 100
      t.boolean :mark_canonical, default: false, null: false
      t.boolean :referential_link, default: true, null: false
      t.references :fallback_organization, foreign_key: { to_table: :organizations, on_delete: :nullify }
      t.references :fallback_author, foreign_key: { to_table: :users, on_delete: :nullify }
      t.integer :status, default: 0, null: false
      t.datetime :last_fetched_at
      t.string :last_error_message

      t.timestamps
    end
  end
end
