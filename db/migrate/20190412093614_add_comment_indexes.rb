class AddCommentIndexes < ActiveRecord::Migration[5.2]
  def change
    add_index :comments, %i[commentable_id commentable_type]
    add_index :comments, :user_id
  end
end
