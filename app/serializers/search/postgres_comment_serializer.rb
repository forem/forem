module Search
  # TODO[@atsmith813]: Rename this to CommentSerializer once Elasticsearch is removed
  class PostgresCommentSerializer < ApplicationSerializer
    attribute :id, &:search_id

    attributes :path, :public_reactions_count

    attribute :body_text, &:body_markdown

    attribute :class_name do |_comment|
      "Comment"
    end

    attribute :highlight do |comment|
      {
        body_text: [comment.pg_search_highlight]
      }
    rescue PgSearch::PgSearchHighlightNotSelected
      # This is needed because in Search::Postgres::Comment we only call the
      # search if a term is provided. This means if a user searches with a
      # blank term, we skip the line that executes .with_pg_search_highlight.
      # Skipping this AND trying to call .pg_search_highlight raises an error
      # which we ignore here - basically filling in highlights if they're
      # there.
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
