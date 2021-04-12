module Search
  module Postgres
    class Comment
      ATTRIBUTES = [
        "articles.published",
        "comments.body_markdown",
        "comments.commentable_id AS commentable_id",
        "comments.commentable_type AS commentable_type",
        "comments.created_at",
        "comments.id AS id",
        "comments.public_reactions_count",
        "comments.score",
        "comments.user_id AS comment_user_id",
        "podcast_episodes.podcast_id AS podcast_id",
        "podcasts.published",
        "users.id AS user_id",
        "users.name",
        "users.profile_image",
        "users.username",
      ].freeze
      private_constant :ATTRIBUTES

      DEFAULT_PER_PAGE = 60
      private_constant :DEFAULT_PER_PAGE

      # Because commentable represents a polymorphic relationship, ActiveRecord
      # can't eager load the associations so we have to make all the joins
      # manually.
      #
      # NOTE: if Comment::COMMENTABLE_TYPES is updated, this filter will also
      # need to be updated
      FORCED_EAGER_LOAD_QUERY = <<-SQL.freeze
        LEFT JOIN users
          ON comments.user_id = users.id
        LEFT JOIN articles
          ON comments.commentable_id = articles.id
          AND comments.commentable_type = 'Article'
        LEFT JOIN podcast_episodes
          ON comments.commentable_id = podcast_episodes.id
          AND comments.commentable_type = 'PodcastEpisode'
        LEFT JOIN podcasts
          ON podcast_episodes.podcast_id = podcasts.id
      SQL
      private_constant :FORCED_EAGER_LOAD_QUERY

      MAX_PER_PAGE = 120 # to avoid querying too many items, we set a maximum amount for a page
      private_constant :MAX_PER_PAGE

      # We filter comments for those that are:
      # 1. Not deleted
      # 2. Not hidden by commentable user (i.e. an Article author didn't hide the comment)
      # 3. Are attached to published content (i.e. Article, Podcast)
      #
      # NOTE: if Comment::COMMENTABLE_TYPES is updated, this filter will also
      # need to be updated
      QUERY_FILTER = <<-SQL.freeze
        comments.deleted = false AND
        comments.hidden_by_commentable_user = false AND
        (articles.published = true OR podcasts.published = true)
      SQL
      private_constant :QUERY_FILTER

      def self.search_documents(page: 0, per_page: DEFAULT_PER_PAGE, term: nil)
        # NOTE: [@rhymes/atsmith813] we should eventually update the frontend
        # to start from page 1
        page = page.to_i + 1
        per_page = [(per_page || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE].min

        relation = ::Comment.joins(FORCED_EAGER_LOAD_QUERY).where(QUERY_FILTER)

        relation = relation.search_comments(term) if term.present?

        relation = relation.select(*ATTRIBUTES).reorder("comments.score": :desc)

        results = relation.page(page).per(per_page)

        serialize(results)
      end

      def self.serialize(results)
        Search::CommentSerializer
          .new(results, is_collection: true)
          .serializable_hash[:data]
          .pluck(:attributes)
      end
      private_class_method :serialize
    end
  end
end
