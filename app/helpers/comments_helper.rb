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

  def user_id_present?(commentable, comment)
    commentable &&
      [
        commentable.user_id,
        commentable.second_user_id,
        commentable.third_user_id
      ].any? { |id| id == comment.user_id }
  end

  def get_ama_or_op_banner(commentable)
    commentable.decorate.cached_tag_list_array.include?("ama") ? "ASK ME ANYTHING" : "OP"
  end
end
