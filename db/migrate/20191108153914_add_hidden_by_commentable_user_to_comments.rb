class AddHiddenByCommentableUserToComments < ActiveRecord::Migration[5.2]
  def change
    add_column :comments, :hidden_by_commentable_user, :boolean, default: false
  end
end
