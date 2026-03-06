class CreateFeedImportLogs < ActiveRecord::Migration[7.0]
  def change
    create_table :feed_import_logs do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.integer :status, null: false, default: 0
      t.integer :items_in_feed, default: 0
      t.integer :items_imported, default: 0
      t.integer :items_skipped, default: 0
      t.integer :items_failed, default: 0
      t.string :error_message
      t.integer :http_status_code
      t.float :duration_seconds
      t.string :feed_url

      t.timestamps
    end

    add_index :feed_import_logs, [:user_id, :created_at]
  end
end
