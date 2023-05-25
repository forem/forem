class AddCompositeIndexToSegmentedUsers < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  def change
    add_index :segmented_users,
              %i[audience_segment_id user_id],
              name: "index_segmented_users_on_audience_segment_and_user",
              unique: true,
              algorithm: :concurrently
  end
end
