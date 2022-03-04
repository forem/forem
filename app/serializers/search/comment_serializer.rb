module Search
  class CommentSerializer < ApplicationSerializer
    attribute :id, &:search_id

    attributes :path do |comment|
      user = comment.user

      if user
        "/#{user.username}/comment/#{comment.id_code_generated}"
      else
        "/404.html"
      end
    end

    attributes :public_reactions_count

    attribute :body_text, &:body_markdown

    attribute :class_name, -> { "Comment" }

    attribute :highlight do |comment|
      {
        body_text: [comment.pg_search_highlight]
      }
    rescue PgSearch::PgSearchHighlightNotSelected
      # This is needed because in Search::Comment we only call the
      # search if a term is provided. This means if a user searches with a
      # blank term, we skip the line that executes .with_pg_search_highlight.
      # Skipping this AND trying to call .pg_search_highlight raises an error
      # which we ignore here - basically filling in highlights if they're
      # there.
      {
        body_text: []
      }
    end

    attribute :hotness_score, &:score
    attribute :published, -> { true }
    attribute :published_at, &:created_at
    attribute :readable_publish_date_string, &:readable_publish_date
    attribute :title, &:commentable_title

    # NOTE: not using the `NestedUserSerializer` to avoid hitting Redis to
    # fetch the cached value
    attribute :user do |comment|
      user = comment.user

      if user
        user.slice(:name, :profile_image_90, :username).symbolize_keys
      else
        {}
      end
    end
  end
end
