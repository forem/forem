module Search
  class CommentSerializer < ApplicationSerializer
    attribute :id, &:search_id

    attributes :path, :public_reactions_count

    attribute :body_text, &:body_markdown
    attribute :class_name do |comment|
      comment.class.name
    end
    attribute :hotness_score, &:score
    attribute :published do |comment|
      comment.commentable&.published
    end
    attribute :published_at, &:created_at
    attribute :readable_publish_date_string, &:readable_publish_date
    attribute :title do |comment|
      comment.commentable&.title
    end

    # NOTE: not using the `NestedUserSerializer` because we don't need the
    # the `pro` flag on the frontend, and we also avoid hitting Redis to
    # fetch the cached value
    attribute :user do |comment|
      user = comment.user

      {
        name: user.name,
        profile_image_90: user.profile_image_90,
        username: user.username
      }
    end
  end
end
