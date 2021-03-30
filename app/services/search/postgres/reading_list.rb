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

      def self.search_documents(
        user, term: nil, statuses: [], tags: [], page: 0, per_page: DEFAULT_PER_PAGE,
        multisearch: false, joined_tables: false, tsvector_column: false, view: false
      )
        return {} unless user

        statuses = statuses.presence || DEFAULT_STATUSES
        tags = tags.presence || []

        # NOTE: [@rhymes] we should eventually update the frontend
        # to start from page 1
        page = page.to_i + 1
        per_page = [(per_page || DEFAULT_PER_PAGE).to_i, MAX_PER_PAGE].min

        result = if multisearch
                   find_articles_multisearch(
                     user: user,
                     term: term,
                     statuses: statuses,
                     tags: tags,
                     page: page,
                     per_page: per_page,
                   )
                 elsif view
                   find_articles_from_view(
                     user: user,
                     term: term,
                     statuses: statuses,
                     tags: tags,
                     page: page,
                     per_page: per_page,
                   )
                 else
                   find_articles(
                     user: user,
                     term: term,
                     statuses: statuses,
                     tags: tags,
                     page: page,
                     per_page: per_page,
                     joined_tables: joined_tables,
                     tsvector_column: tsvector_column,
                   )
                 end

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
          items: serialize(result[:items], users, view: view),
          total: result[:total]
        }
      end

      def self.find_articles(user:, term:, statuses:, tags:, page:, per_page:, joined_tables:, tsvector_column:)
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

        relation = Article.joins("INNER JOIN (#{reaction_query_sql}) reactions ON reactions.reactable_id = articles.id")

        if term.present?
          relation = if tsvector_column
                       relation.search_reading_list_tsvector_column(term)
                     elsif joined_tables
                       relation.search_reading_list_joined_tables(term)
                     else
                       relation.search_reading_list_single_table(term)
                     end
        end

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
        # An alternative solution, as we don't need the `Tag` model itself, is to use
        # `articles.cached_tag_list` and the `LIKE` operator on it, this could be further
        # improved, if needed, by adding a GIN index on `cached_tag_list`
        # It seems not to be needed as this approach is roughly 1850 times faster than the previous
        # see https://explain.depesz.com/s/ajoP / https://explain.dalibo.com/plan/PZb
        tags.each do |tag|
          relation = relation.where("articles.cached_tag_list LIKE ?", "%#{tag}%")
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

      def self.find_articles_from_view(user:, term:, statuses:, tags:, page:, per_page:)
        relation = ::ReadingList.where(reaction_user_id: user.id, reaction_status: statuses)

        relation = relation.search_reading_list(term) if term.present?

        tags.each do |tag|
          relation = relation.where("cached_tag_list LIKE ?", "%#{tag}%")
        end

        total = relation.count

        relation = relation.order(reaction_created_at: :desc).page(page).per(per_page)

        {
          items: relation,
          total: total
        }
      end
      private_class_method :find_articles_from_view

      # [@rhymes] this is at least 10 times slower than the trigger based solution
      # => not surprising as, even if it uses a tsvector index, it doesn't use a tsvector column
      def self.find_articles_multisearch(user:, term:, statuses:, tags:, page:, per_page:)
        reactions = user.reactions.readinglist
          .where(status: statuses, reactable_type: "Article")
          .order(created_at: :desc)
          .select(*REACTION_ATTRIBUTES)

        relation = PgSearch.multisearch(term)
          .preload(:searchable)
          .where(searchable_type: "Article")
          .where(searchable_id: reactions.reselect(:reactable_id))

        # NOTE: this could be simplified by moving `cached_tag_list` as an attribute of `pg_search_documents`
        if tags.present?
          relation = relation
            .joins("INNER JOIN articles ON pg_search_documents.searchable_id = articles.id")

          tags.each do |tag|
            relation = relation.where("articles.cached_tag_list LIKE ?", "%#{tag}%")
          end
        end

        total = relation.count

        relation = relation.page(page).per(per_page)

        reactions = reactions.index_by(&:reactable_id)
        items = relation.map do |doc|
          article = doc.searchable
          reaction = reactions[article.id]

          article.reaction_id = reaction.id
          article.reaction_user_id = reaction.user_id

          article
        end

        {
          items: items,
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

      def self.serialize(articles, users, view:)
        serializer = view ? ::Search::ReadingListItemSerializer : ::Search::ReadingListArticleSerializer
        serializer
          .new(articles, params: { users: users }, is_collection: true)
          .serializable_hash[:data]
          .pluck(:attributes)
      end
      private_class_method :serialize
    end
  end
end
