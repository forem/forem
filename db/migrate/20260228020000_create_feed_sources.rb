class CreateFeedSources < ActiveRecord::Migration[7.0]
  def change
    create_table :feed_sources do |t|
      t.references :user, null: false, foreign_key: { on_delete: :cascade }
      t.string :feed_url, null: false, limit: 500
      t.string :name, limit: 100
      t.references :organization, null: true, foreign_key: { on_delete: :nullify }
      t.bigint :author_user_id
      t.boolean :mark_canonical, default: false, null: false
      t.boolean :referential_link, default: true, null: false
      t.integer :status, default: 0, null: false
      t.string :status_message
      t.integer :consecutive_failures, default: 0, null: false
      t.datetime :last_fetched_at

      t.timestamps
    end

    add_foreign_key :feed_sources, :users, column: :author_user_id, on_delete: :nullify, validate: false
    add_index :feed_sources, %i[user_id feed_url], unique: true
  end
end
