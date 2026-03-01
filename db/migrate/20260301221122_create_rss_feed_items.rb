class CreateRssFeedItems < ActiveRecord::Migration[7.0]
  def change
    create_table :rss_feed_items do |t|
      t.references :rss_feed, null: false, foreign_key: { on_delete: :cascade }
      t.references :article, foreign_key: { on_delete: :nullify }
      t.string :item_url, null: false, limit: 1000
      t.string :title, limit: 512
      t.integer :status, default: 0, null: false
      t.string :error_message
      t.string :skip_reason
      t.datetime :detected_at
      t.datetime :processed_at

      t.timestamps
    end
  end
end
