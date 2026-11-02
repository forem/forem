class AddStickyFeedConfigAssignments < ActiveRecord::Migration[8.0]
  def change
    # Separate calls allow Strong Migrations to inspect each column addition.
    # rubocop:disable Rails/BulkChangeTable
    add_column :feed_configs, :feed_repeat_visits_count, :bigint, default: 0, null: false
    add_column :feed_configs, :feed_impression_users_count, :bigint, default: 0, null: false
    # rubocop:enable Rails/BulkChangeTable

    create_table :feed_config_assignments do |t|
      t.references :user, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :subforem, index: false, foreign_key: { on_delete: :cascade }
      t.references :feed_config, index: false, foreign_key: { on_delete: :nullify }
      t.datetime :expires_at
      t.datetime :last_rewarded_at
      t.timestamps
    end
  end
end
