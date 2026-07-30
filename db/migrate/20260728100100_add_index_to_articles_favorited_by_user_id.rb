class AddIndexToArticlesFavoritedByUserId < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    return if index_exists?(:articles, :favorited_by_user_id)

    add_index :articles, :favorited_by_user_id, algorithm: :concurrently
  end

  def down
    return unless index_exists?(:articles, :favorited_by_user_id)

    remove_index :articles, :favorited_by_user_id, algorithm: :concurrently
  end
end
