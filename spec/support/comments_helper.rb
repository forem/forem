module CommentsHelpers
  FLAGGED_CATEGORIES = %w[thumbsdown vomit].freeze

  def create_comment_time_ago(user_id, time_ago, flagged_by: nil, commentable: nil)
    comment = create(
      :comment,
      commentable: commentable || create(:article),
      user_id: user_id,
      created_at: time_ago,
    )
    # User default self-like
    create(
      :reaction,
      user_id: user_id,
      reactable_id: comment.id,
      reactable_type: "Comment",
    )

    return if flagged_by.nil?

    create(
      :reaction,
      user_id: flagged_by.id,
      category: FLAGGED_CATEGORIES.sample,
      reactable_id: comment.id,
      reactable_type: "Comment",
    )
  end
end
