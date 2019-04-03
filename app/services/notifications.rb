module Notifications
  def self.user_data(user)
    {
      id: user.id,
      class: { name: "User" },
      name: user.name,
      username: user.username,
      path: user.path,
      profile_image_90: user.profile_image_90,
      comments_count: user.comments_count,
      created_at: user.created_at
    }
  end

  def self.comment_data(comment)
    {
      id: comment.id,
      class: { name: "Comment" },
      path: comment.path,
      processed_html: comment.processed_html,
      updated_at: comment.updated_at,
      commentable: {
        id: comment.commentable.id,
        title: comment.commentable.title,
        path: comment.commentable.path,
        class: {
          name: comment.commentable.class.name
        }
      }
    }
  end
end
