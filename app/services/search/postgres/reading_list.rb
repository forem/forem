# TODO: [@rhymes]:
# => add index on reactions.status
# => add GIN index on tags.name OR on articles.cached_tag_list
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

      def self.search_documents(user, statuses: [], tags: [], page: 1, per_page: DEFAULT_PER_PAGE)
        statuses = statuses.presence || DEFAULT_STATUSES
        tags ||= []

        # NOTE: [@rhymes] we should eventually update the frontend
        # to start from page 1
        page = page.to_i + 1
        per_page = [(per_page || DEFAULT_PER_PAGE).to_i, 100].min

        total = user.reactions.readinglist.where(status: statuses).count

        articles = find_articles(
          user_id: user.id,
          statuses: statuses,
          tags: tags,
          page: page,
          per_page: per_page,
        )

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
        user_ids = articles.pluck(:user_id)
        users = find_users(user_ids)

        {
          items: serialize(articles, users),
          total: total
        }
      end

      def self.find_articles(user_id:, statuses:, tags:, page:, per_page:)
        relation = ::Article
          .joins(:reactions)
          .select(*ATTRIBUTES)
          .where("reactions.category": :readinglist)
          .where("reactions.user_id": user_id)
          .where("reactions.status": statuses)
          .order("reactions.created_at": :desc)

        # NOTE: [@rhymes] A few details:
        # =>`.tagged_with()` merges `articles.*` to the SQL, thus we need to
        #    use `reselect()`, see https://github.com/forem/forem/pull/12420
        # => `.tagged_with()` with multiple tags constructs a monster query,
        #    see https://explain.depesz.com/s/CqQV / https://explain.dalibo.com/plan/1Lm
        # This is because the `acts-as-taggable-on` query creates a separate INNER JOIN
        # each tag is added to filter for, each new clause uses the `LIKE` operator on `tags.name`
        # A possible way to improve a bit would be to add a GIN index on `tags.name`, see
        # https://www.cybertec-postgresql.com/en/postgresql-more-performance-for-like-and-ilike-statements/
        # and a similar discussion https://github.com/forem/forem/pull/12584#discussion_r570756176
        # relation = relation.tagged_with(tags, any: false).reselect(*ATTRIBUTES) if tags.present?

        # An alternative solution, as we don't need the `Tag` model, is to use
        # `articles.cached_tag_list` and the `LIKE` operator, this could be further
        # improved, if needed, by adding a GIN index on `cached_tag_list`
        # It seems not to be needed as this approach is roughly 1850 times faster
        # see https://explain.depesz.com/s/ajoP / https://explain.dalibo.com/plan/PZb
        tags.each do |tag|
          relation = relation.where("articles.cached_tag_list LIKE ?", "%#{tag}%")
        end

        relation.page(page).per(per_page)
      end
      private_class_method :find_articles

      def self.find_users(user_ids)
        ::User
          .where(id: user_ids)
          .select(*USER_ATTRIBUTES)
          .index_by(&:id)
      end
      private_class_method :find_users

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
