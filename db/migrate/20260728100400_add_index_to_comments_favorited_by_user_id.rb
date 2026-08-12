class AddIndexToCommentsFavoritedByUserId < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    return if index_exists?(:comments, :favorited_by_user_id)

    add_index :comments, :favorited_by_user_id, algorithm: :concurrently
  end

  def down
    return unless index_exists?(:comments, :favorited_by_user_id)

    remove_index :comments, :favorited_by_user_id, algorithm: :concurrently
  end
end
