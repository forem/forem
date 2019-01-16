module CommentsHelper
  def comment_class(comment, is_view_root = false)
    if comment.root? || is_view_root
      "root"
    else
      "child"
    end
  end

  def comment_user_id_unless_deleted(comment)
    comment.deleted ? 0 : comment.user_id
  end

  def tree_for(comment, commentable)
    nested_comments(tree: comment.subtree.includes(:user).arrange, commentable: commentable, is_view_root: true)
  end

  private

  def nested_comments(tree:, commentable:, is_view_root: false)
    tree.map do |comment, sub_comments|
      render("comments/comment", comment: comment, commentable: commentable,
                                 is_view_root: is_view_root, is_childless: sub_comments.empty?,
                                 subtree_html: nested_comments(tree: sub_comments, commentable: commentable))
    end.join.html_safe
  end
end
