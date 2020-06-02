class AddUniqueIndexesToCommentsBodyMarkdownUserIdAncestryCommentable < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    return if index_exists?(
      :comments,
      %i[body_markdown user_id ancestry commentable_id commentable_type],
      name: :index_comments_on_body_markdown_user_id_ancestry_commentable
    )

    add_index(
      :comments,
      %i[body_markdown user_id ancestry commentable_id commentable_type],
      unique: true,
      algorithm: :concurrently,
      name: :index_comments_on_body_markdown_user_id_ancestry_commentable
    )
  end

  def down
    return unless index_exists?(
      :comments,
      %i[body_markdown user_id ancestry commentable_id commentable_type],
      name: :index_comments_on_body_markdown_user_id_ancestry_commentable
    )

    remove_index(
      :comments,
      name: :index_comments_on_body_markdown_user_id_ancestry_commentable,
      algorithm: :concurrently
    )
  end
end
