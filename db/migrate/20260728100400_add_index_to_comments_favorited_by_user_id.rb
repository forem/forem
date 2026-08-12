class AddIndexToCommentsFavoritedByUserId < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def up
    safety_assured do
      execute "SET statement_timeout = 0;"
      remove_index :comments, name: "index_comments_on_favorited_by_user_id", if_exists: true, algorithm: :concurrently
      add_index :comments, :favorited_by_user_id, algorithm: :concurrently
    end
  end

  def down
    safety_assured do
      execute "SET statement_timeout = 0;"
      remove_index :comments, name: "index_comments_on_favorited_by_user_id", if_exists: true, algorithm: :concurrently
    end
  end
end
