class AddStickyFeedConfigAssignments < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    change_table :feed_configs, bulk: true do |t|
      t.bigint :feed_repeat_visits_count, default: 0, null: false
      t.bigint :feed_impression_users_count, default: 0, null: false
    end

    create_table :feed_config_assignments do |t|
      t.references :user, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.references :subforem, index: false, foreign_key: { on_delete: :cascade }
      t.references :feed_config, index: false, foreign_key: { on_delete: :nullify }
      t.datetime :expires_at
      t.datetime :last_rewarded_at
      t.timestamps
    end

    add_index :feed_config_assignments, %i[user_id subforem_id], unique: true,
                                                                 where: "subforem_id IS NOT NULL",
                                                                 algorithm: :concurrently
    add_index :feed_config_assignments, :user_id, unique: true,
                                                  where: "subforem_id IS NULL",
                                                  name: "index_feed_config_assignments_on_unscoped_user",
                                                  algorithm: :concurrently
    add_index :feed_config_assignments, :subforem_id, algorithm: :concurrently
    add_index :feed_config_assignments, :feed_config_id, algorithm: :concurrently
  end
end
