class AddUniqueIndexesToCommentsBodyMarkdownUserIdAncestryCommentable < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def change
    add_index(
      :comments,
      %i[body_markdown user_id ancestry commentable_id commentable_type],
      unique: true,
      algorithm: :concurrently,
      name: :index_comments_on_body_markdown_user_id_ancestry_commentable
    )
  end
end
