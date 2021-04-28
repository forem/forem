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
      REACTION_ATTRIBUTES = %i[id reactable_id user_id].freeze
      USER_ATTRIBUTES = %i[id name profile_image username].freeze

      DEFAULT_STATUSES = %w[confirmed valid].freeze

      DEFAULT_PER_PAGE = 60
      MAX_PER_PAGE = 100 # to avoid querying too many items, we set a maximum amount for a page

      def self.search_documents(user, term: nil, statuses: [], tags: [], page: 0, per_page: DEFAULT_PER_PAGE)
        return {} unless user

        statuses = statuses.presence || DEFAULT_STATUSES
        tags = tags.presence || []

        # TODO: [@rhymes] we should eventually update the frontend
        # to start from page 1
        page = page.to_i + 1
        per_page = [(per_page || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE].min

        result = find_articles(
          user: user,
          term: term,
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
        user_ids = result[:items].pluck(:user_id)
        users = find_users(user_ids)

        {
          items: serialize(result[:items], users),
          total: result[:total]
        }
      end

      def self.find_articles(user:, term:, statuses:, tags:, page:, per_page:)
        # [@jgaskins, @rhymes] as `reactions` is potentially a big table, adding pagination
        # to an INNER JOIN (eg. `joins(:reactions)`) exponentially decreases the performance,
        # incrementing query time as the database has to scan all the rows just to discard
        # them right after if they lie outside the bounds of the `OFFSET`.
        # Even though it should have had a similar performance, we realized that a subquery
        # enabled PostgreSQL query planner to drastically decrease the planned time (ca. 145x)
        reaction_query_sql = user.reactions.readinglist
          .where(status: statuses, reactable_type: "Article")
          .order(created_at: :desc)
          .select(*REACTION_ATTRIBUTES)
          .to_sql

        relation = ::Article.joins(
          "INNER JOIN (#{reaction_query_sql}) reactions ON reactions.reactable_id = articles.id",
        )

        relation = relation.search_articles(term) if term.present?

        # NOTE: [@rhymes] A previous version was implemented with:
        # `.tagged_with(tags, any: false).reselect(*ATTRIBUTES)`
        #
        # =>`.tagged_with()` merges `articles.*` to the SQL, thus we needed to
        #    use `reselect()`, see https://github.com/forem/forem/pull/12420
        # => `.tagged_with()` with multiple tags constructs a monster query,
        #    see https://explain.depesz.com/s/CqQV / https://explain.dalibo.com/plan/1Lm
        # This is because the `acts-as-taggable-on` query creates a separate INNER JOIN
        # per each tag that is added to the list, each new clause uses the `LIKE` operator on `tags.name`.
        # That could have been improved by by adding a GIN index on `tags.name`, see
        # https://www.cybertec-postgresql.com/en/postgresql-more-performance-for-like-and-ilike-statements/
        # and a similar discussion https://github.com/forem/forem/pull/12584#discussion_r570756176
        #
        # The preferred solution, as we don't need the `Tag` model itself, is to use
        # `articles.cached_tag_list` and the `~` regexp operator with it
        tags.each do |tag|
          relation = relation.where("articles.cached_tag_list ~ ?", "#{tag}\\M")
        end

        # here we issue a COUNT(*) after all the conditions are applied,
        # because we need to fetch the total number of articles, pre pagination
        total = relation.count

        relation = relation.select(*ATTRIBUTES)
        relation = relation.page(page).per(per_page)

        {
          items: relation,
          total: total
        }
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
