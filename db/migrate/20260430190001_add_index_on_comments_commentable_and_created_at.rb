class AddIndexOnCommentsCommentableAndCreatedAt < ActiveRecord::Migration[7.0]
  disable_ddl_transaction!

  # Speeds up date-bounded analytics queries that join on
  # (commentable_id, commentable_type) and then filter by created_at.
  def change
    add_index :comments,
              %i[commentable_id commentable_type created_at],
              name: "index_comments_on_commentable_and_created_at",
              algorithm: :concurrently
  end
end
