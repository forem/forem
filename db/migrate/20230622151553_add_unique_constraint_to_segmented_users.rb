class AddUniqueConstraintToSegmentedUsers < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def up
    # remove the old index first
    remove_index :segmented_users, name: "index_segmented_users_on_audience_segment_and_user", algorithm: :concurrently

    # add a new index with uniqueness constraint
    add_index :segmented_users,
              %i[audience_segment_id user_id],
              unique: true,
              name: "index_segmented_users_on_audience_segment_and_user",
              algorithm: :concurrently
  end

  def down
    # to reverse the migration, remove the unique index
    remove_index :segmented_users, name: "index_segmented_users_on_audience_segment_and_user", algorithm: :concurrently

    # and add back the old index
    add_index :segmented_users,
              %i[audience_segment_id user_id],
              name: "index_segmented_users_on_audience_segment_and_user",
              algorithm: :concurrently
  end
end