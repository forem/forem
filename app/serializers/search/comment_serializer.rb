module Search
  class CommentSerializer
    include FastJsonapi::ObjectSerializer

    attribute :id, &:search_id

    attributes :path, :positive_reactions_count

    attribute :body_text, &:body_markdown
    attribute :class_name do |comment|
      comment.class.name
    end
    attribute :hotness_score, &:score
    attribute :published do |_comment|
      true
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
