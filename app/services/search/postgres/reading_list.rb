# TODO: [@rhymes]:
# => add index on reactions.status
# => preload data to optimize serialization queries?
# => ArticleSerializer serializes everything and it's for ES, but do we need all that data for the frontend?
module Search
  module Postgres
    class ReadingList
      ATTRIBUTES = [
        "articles.cached_tag_list",
        "articles.crossposted_at",
        "articles.path",
        "articles.published_at",
        "articles.reading_time",
        "articles.title",
        "articles.user_id",
        "reactions.id AS reaction_id",
        "reactions.user_id AS reaction_user_id",
      ].freeze
      DEFAULT_PER_PAGE = 60
      DEFAULT_STATUSES = %w[valid confirmed].freeze

      def self.search_documents(user, statuses: [], page: 1, per_page: DEFAULT_PER_PAGE)
        statuses = statuses.presence || DEFAULT_STATUSES

        # NOTE: [@rhymes] we should eventually update the frontend
        # to start from page 1
        page = page.to_i.zero? ? 1 : page.to_i
        per_page = [(per_page || DEFAULT_PER_PAGE).to_i, 100].min

        # https://dev.to/admin/blazer/queries/349-reading-list-articles-query-plan
        results = Article
          .joins(:reactions)
          .includes(:user)
          .select(*ATTRIBUTES)
          .where("reactions.category": :readinglist)
          .where("reactions.user_id": user.id)
          .where("reactions.status": statuses)
          .order("reactions.created_at": :desc)
          .page(page)
          .per(per_page)

        serialize(results)
      end

      def self.serialize(results)
        Search::ReadingListArticleSerializer.new(results, is_collection: true)
          .serializable_hash[:data]
          .pluck(:attributes)
      end
      private_class_method :serialize
    end
  end
end
