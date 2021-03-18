# TODO: [@rhymes]:
# => add index on reactions.status
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
      USER_ATTRIBUTES = %i[id name profile_image username].freeze
      DEFAULT_PER_PAGE = 60
      DEFAULT_STATUSES = %w[confirmed valid].freeze

      def self.search_documents(user, statuses: [], page: 1, per_page: DEFAULT_PER_PAGE)
        statuses = statuses.presence || DEFAULT_STATUSES

        # NOTE: [@rhymes] we should eventually update the frontend
        # to start from page 1
        page = page.to_i.zero? ? 1 : page.to_i
        per_page = [(per_page || DEFAULT_PER_PAGE).to_i, 100].min

        total = user.reactions.readinglist.where(status: statuses).count

        articles = Article
          .joins(:reactions)
          .select(*ATTRIBUTES)
          .where("reactions.category": :readinglist)
          .where("reactions.user_id": user.id)
          .where("reactions.status": statuses)
          .order("reactions.created_at": :desc)
          .page(page)
          .per(per_page)

        # NOTE: [@rhymes] an earlier version used `Article.includes(:user)`
        # to preload users, unfortunately it's not possible in Rails to specify
        # which fields of the included relation's table to select ahead of time.
        # The `users` table is massive (115 columns on March 2021) and thus we
        # shouldn't load it all in memory just to select a few fields.
        # For these reasons I decided to avoid preloading altogether and issue
        # an additional SQL query to load User objects
        # (see https://github.com/forem/forem/pull/4744#discussion_r345698674
        # and https://github.com/rails/rails/issues/15185#issuecomment-351868335
        # for additional context)
        users = ::User
          .where(id: articles.pluck(:user_id))
          .select(*USER_ATTRIBUTES)
          .index_by(&:id)

        {
          items: serialize(articles, users),
          total: total
        }
      end

      def self.serialize(articles, users)
        Search::ReadingListArticleSerializer
          .new(articles, params: { users: users }, is_collection: true)
          .serializable_hash[:data]
          .pluck(:attributes)
      end
      private_class_method :serialize
    end
  end
end
