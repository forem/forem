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

    attribute :user do |comment|
      NestedUserSerializer.new(comment.user).serializable_hash.dig(
        :data, :attributes
      )
    end
  end
end
