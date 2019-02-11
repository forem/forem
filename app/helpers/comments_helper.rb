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

  def tree_for(comment, sub_comments, commentable)
    Comments::Tree.new(context: self, comment: comment, sub_comments: sub_comments, commentable: commentable).display
  end
end
