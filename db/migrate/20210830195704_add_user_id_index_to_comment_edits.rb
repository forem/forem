class AddUserIdIndexToCommentEdits < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!

  def change
    add_index :comment_edits, :editor_id, algorithm: :concurrently
  end
end
