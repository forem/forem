class AddIndexesToFeedConfigAssignments < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
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
