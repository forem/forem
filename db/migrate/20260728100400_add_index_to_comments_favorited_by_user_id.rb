class AddIndexToCommentsFavoritedByUserId < ActiveRecord::Migration[8.0]
  def up
    safety_assured do
      remove_index :comments, name: "index_comments_on_favorited_by_user_id", if_exists: true
      add_index :comments, :favorited_by_user_id, if_not_exists: true
    end
  end

  def down
    safety_assured do
      remove_index :comments, name: "index_comments_on_favorited_by_user_id", if_exists: true
    end
  end
end
