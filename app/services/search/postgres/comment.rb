module Search
  module Postgres
    class Comment
      ATTRIBUTES = [
        "comments.id AS id",
        "comments.body_markdown",
        "comments.commentable_id",
        "comments.commentable_type",
        "comments.created_at",
        "comments.public_reactions_count",
        "comments.score",
        "comments.user_id AS comment_user_id",
        "users.id AS user_id",
        "users.name",
        "users.profile_image",
        "users.username",
      ].freeze
      private_constant :ATTRIBUTES

      DEFAULT_PER_PAGE = 60
      private_constant :DEFAULT_PER_PAGE

      MAX_PER_PAGE = 120 # to avoid querying too many items, we set a maximum amount for a page
      private_constant :MAX_PER_PAGE

      def self.search_documents(page: 0, per_page: DEFAULT_PER_PAGE, term: nil)
        # NOTE: [@rhymes/atsmith813] we should eventually update the frontend
        # to start from page 1
        page = page.to_i + 1
        per_page = [(per_page || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE].min

        relation = ::Comment
          .force_eager_load_serialized_data
          .where(
            comments: {
              deleted: false,
              hidden_by_commentable_user: false
            },
          )

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
