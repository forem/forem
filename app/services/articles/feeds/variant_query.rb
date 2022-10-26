module Articles
  module Feeds
    # This object is responsible for building the relevancy feed based on the given user and the
    # variant they are currently assigned.
    #
    # This class uses the Articles::Feeds::VariantQuery::Config to create a SQL statement.  The SQL
    # statement calculates a `relevancy_score` for each article based on the configuration of the
    # chosen relevancy levers.
    #
    # @see config/feed-variants/README.md
    # @see app/models/articles/feeds/README.md
    class VariantQuery
      # @api public
      #
      # @param variant [Symbol, #to_sym] the name of the variant query we're building.
      # @param assembler [Articles::Feeds::VariantAssembler, #call] responsible for converting the
      #        given variant to a config suitable for building a VariantQuery.
      # @param kwargs [Hash] named parameters to pass along to the #initialize method.
      #
      # @return [Articles::Feeds::VariantQuery]
      #
      # @see #initialize
      def self.build_for(variant:, assembler: VariantAssembler, **kwargs)
        config = assembler.call(variant: variant)
        new(config: config, **kwargs)
      end

      Config = Struct.new(
        :variant,
        :description,
        :levers, # Array <Articles::Feeds::RelevancyLever::Configured>
        :order_by, # Articles::Feeds::OrderByLever
        :max_days_since_published,
        # when true, each time you call the query you will get different randomized numbers; when
        # false, the resulting randomized numbers will be the same within a window of time.
        :reseed_randomizer_on_each_request,
        keyword_init: true,
      ) do
        alias_method :reseed_randomizer_on_each_request?, :reseed_randomizer_on_each_request
      end

      # @param config [Articles::Feeds::VariantQuery::Config]
      # @param user [User,NilClass]
      # @param number_of_articles [Integer, #to_i]
      # @param page [Integer, #to_i]
      # @param tag [NilClass] not used
      #
      # @param seed [Number] used in the `setseed` Postgresql function to set the randomization
      #        seed.  This parameter allows the caller (and debugger) to use the same randomization
      #        order in the queries; the hope being that this might help in any debugging.
      def initialize(config:, user: nil, number_of_articles: 50, page: 1, tag: nil, seed: nil)
        @user = user
        @number_of_articles = number_of_articles
        @page = page
        @tag = tag
        @config = config
        @seed = randomizer_seed_for(seed: seed, user: user)
        oldest_published_at = Articles::Feeds.oldest_published_at_to_consider_for(
          user: @user,
          days_since_published: config.max_days_since_published,
        )
        @query_parameters = { oldest_published_at: oldest_published_at }
        configure!
      end

      attr_reader :config, :query_parameters, :seed

      # Query for articles relevant to the user's interest.
      #
      # @param only_featured [Boolean] select only articles that are "featured"
      # @param must_have_main_image [Boolean] select only articles that have a main image.
      # @param limit [Integer] the number of records to return
      # @param offset [Integer] start the paging window at the given offset
      # @param omit_article_ids [Array] don't include these articles in the search results
      #
      # @return ActiveRecord::Relation for Article
      #
      # @note This creates a complicated SQL query; well actually an ActiveRecord::Relation object
      #       on which you can call `to_sql`.  Which you might find helpful to see what's really
      #       going on.  A great place to do this is in the corresponding spec file.  See the
      #       example below:
      #
      # @example
      #
      #    user = User.first
      #    strategy = Articles::Feed::VariantQuery.build_for(variant: :original, user: user)
      #    puts strategy.call.to_sql
      #
      # rubocop:disable Layout/LineLength
      def call(only_featured: false, must_have_main_image: false, limit: default_limit, offset: default_offset, omit_article_ids: [])
        # rubocop:enable Layout/LineLength

        # These are the variables we'll pass to the SQL statement.
        repeated_query_variables = query_parameters.merge(
          omit_article_ids: omit_article_ids,
          now: Time.current,
          user_id: @user&.id,
        )

        # This needs to be an Array for Article.sanitize_sql.
        unsanitized_sql_sub_query = [
          sql_sub_query(
            only_featured: only_featured,
            must_have_main_image: must_have_main_image,
            limit: limit,
            offset: offset,
            omit_article_ids: omit_article_ids,
          ),
          repeated_query_variables,
        ]

        # Following this blog post: https://pganalyze.com/blog/active-record-subqueries-rails#the-from-subquery
        #
        # We're using the above `unsanitized_sql_sub_query` to create a result set so we can join to
        # articles and then sort on the attributes on either the article or the result set
        # (e.g. sort on the relevancy score).
        join_fragment = Arel.sql(
          "INNER JOIN (" \
          "\n--- The setseed needs to be called independently; later we reference seeder \n" \
          "WITH seeder AS (SELECT setseed(#{Float(@seed)})) " \
          "\n--- We are using the inner logic to build relevancy score" \
          "\n--- The outer part, with seeder, is to create a stable randomized number \n" \
          "SELECT inner_article_relevancies.id, " \
          "inner_article_relevancies.relevancy_score, " \
          "RANDOM() AS randomized_value " \
          "FROM seeder, " \
          "(#{Article.sanitize_sql(unsanitized_sql_sub_query)}) AS inner_article_relevancies" \
          ") AS article_relevancies ON articles.id = article_relevancies.id",
        )

        # This sub-query allows us to take the hard work of the hand-coded unsanitized sql and
        # create a sub-query that we can use to help ensure that we can use all of the ActiveRecord
        # goodness of scopes (e.g., limited_column_select) and eager includes.
        Article.joins(join_fragment)
          .limited_column_select
          .includes(top_comments: :user)
          .order(config.order_by.to_sql)
      end

      alias more_comments_minimal_weight_randomized call

      # Provided as a means to align interfaces with existing feeds.
      #
      # @note I really dislike this method name as it is opaque on
      #       it's purpose.
      # @note We're specifically In the LargeForemExperimental implementation, the
      #       default home feed omits the featured story.  In this
      #       case, I don't want to do that.  Instead, I want to see
      #       how this behaves.
      def default_home_feed(**)
        call
      end

      # The featured story should be the article that:
      #
      # - has the highest relevance score for the nil_user version
      # - has a main image (see note below).
      #
      # The other articles should use the nil_user version and require the `featured = true`
      # attribute.  In my envisioned implementation, the pagination would omit the featured story.
      #
      # @return [Array<Article, Array<Article>] a featured story
      #         Article and an array of Article objects.
      #
      # @note Per prior work, a featured story is the article that has a main image, is marked as
      #       featured (e.g., featured = true), and has the highest relevance score.  In the
      #       Articles::Feeds::LargeForemExperimental object we used the hotness_score to determine
      #       which to use.  The hotness score is most analogue to how this class calculates the
      #       relevance score when we don't have a user.
      #
      # @note There are requests to allow for the featured article to NOT require a main image.
      #       We're still talking through what that means.  This work relates to PR #15333.
      #
      # @note including the ** operator to mirror the method interface of the other feed strategies.
      #
      # @todo In other implementations, when user's aren't signed in we favor featured stories.  But
      #       not so much that they're in the featured story.  For non-signed in users, we may want
      #       to use a completely different set of scoring methods.
      #
      # @note The logic of Articles::Feeds::FindFeaturedStory does not (at present) filter apply an
      #       `Article.featured` scope.  [@jeremyf] I have reported this in
      #       https://github.com/forem/forem/issues/15613 to get clarity from product.
      def featured_story_and_default_home_feed(**)
        # the below implementation creates additional downstream complexities.
        articles = call
        featured_story = Articles::Feeds::FindFeaturedStory.call(articles)
        [featured_story, articles]
      end

      private

      def configure!
        @relevance_score_components = []

        # By default we always need to group by the `articles.id` column.  And as we apply relevancy
        # levers to the query, we need to add additional group_by clauses based on the chosen
        # relevancy levers.
        @group_by_fields = Set.new
        @group_by_fields << "articles.id"

        @joins = Set.new

        # Ensure that we honor a user's block requests.
        unless @user.nil?
          @joins << "LEFT OUTER JOIN user_blocks
            ON user_blocks.blocked_id = articles.user_id
              AND user_blocks.blocked_id IS NULL
              AND user_blocks.blocker_id = :user_id"
        end

        config.levers.each do |lever|
          # Don't attempt to use this factor if we don't have user.
          next if lever.user_required? && @user.nil?

          # This scoring method requires a group by clause.
          @group_by_fields << lever.group_by_fragment if lever.group_by_fragment.present?

          @joins += lever.joins_fragments if lever.joins_fragments.present?

          @relevance_score_components << build_score_element_from(
            select_fragment: lever.select_fragment,
            cases: lever.cases,
            fallback: lever.fallback,
          )

          # As implemented, this is not looking for collisions of named parameters.
          @query_parameters.merge!(lever.query_parameters)
        end
      end

      # Concatenate the required group by clauses.
      #
      # @return [String]
      def group_by_fields_as_sql
        @group_by_fields.join(", ")
      end

      # The sql statement for selecting based on relevance scores
      def sql_sub_query(limit:, offset:, omit_article_ids:, only_featured: false, must_have_main_image: false)
        where_clause = build_sql_with_where_clauses(
          only_featured: only_featured,
          must_have_main_image: must_have_main_image,
          omit_article_ids: omit_article_ids,
        )
        <<~THE_SQL_STATEMENT
          SELECT articles.id, (#{relevance_score_components_as_sql}) as relevancy_score
          FROM articles
          #{joins_clauses_as_sql}
          WHERE #{where_clause}
          GROUP BY #{group_by_fields_as_sql}
          ORDER BY relevancy_score DESC,
            articles.published_at DESC
          #{offset_and_limit_clause(offset: offset, limit: limit)}
        THE_SQL_STATEMENT
      end

      def build_sql_with_where_clauses(only_featured:, must_have_main_image:, omit_article_ids:)
        where_clauses = "articles.published = true AND articles.published_at > :oldest_published_at"
        # See Articles.published scope discussion regarding the query planner
        where_clauses += " AND articles.published_at < :now"
        where_clauses += " AND articles.score >= 0" # We only want positive values here.

        # Without the compact, if we have `omit_article_ids: [nil]` we
        # have the following SQL clause: `articles.id NOT IN (NULL)`
        # which will immediately omit EVERYTHING from the query.
        where_clauses += " AND articles.id NOT IN (:omit_article_ids)" unless omit_article_ids.compact.empty?
        where_clauses += " AND articles.featured = true" if only_featured
        where_clauses += " AND articles.main_image IS NOT NULL" if must_have_main_image
        where_clauses
      end

      def offset_and_limit_clause(offset:, limit:)
        if offset.to_i.positive?
          Article.sanitize_sql_array(["OFFSET ? LIMIT ?", offset, limit])
        else
          Article.sanitize_sql_array(["LIMIT ?", limit])
        end
      end

      def joins_clauses_as_sql
        # This is to just make things legible if we do `to_sql` on the ActiveRecord::Relation object
        @joins.join("\n")
      end

      # We multiply the relevance score components together.
      def relevance_score_components_as_sql
        @relevance_score_components.join(" * \n")
      end

      def default_limit
        @number_of_articles.to_i
      end

      def default_offset
        return 0 if @page == 1

        @page.to_i - (1 * default_limit)
      end

      # We want to ensure that we're not randomizing someone's feed all the time; and instead aiming
      # for somewhat repeatable experiences (e.g. I refresh the page it is likely I will have the
      # same order of pages even though we've randomized things a bit).
      def randomizer_seed_for(seed:, user:)
        return Float(seed) if seed

        return rand if config.reseed_randomizer_on_each_request?

        # This is added as a short-circuit in-case the caching proves to be non-performant.  Once
        # this has been merged, given that it's part of the main loop, we can remove the FeatureFlag
        # a week or so after we merge.
        return rand if FeatureFlag.enabled?(:halt_caching_for_feeds_random_seed)

        # From https://api.rubyonrails.org/classes/ActiveSupport/Cache/Store.html#method-i-fetch
        #
        # Setting :race_condition_ttl is very useful in situations where a cache entry is used very
        # frequently and is under heavy load. If a cache expires and due to heavy load several
        # different processes will try to read data natively and then they all will try to write to
        # cache. To avoid that case the first process to find an expired cache entry will bump the
        # cache expiration time by the value set in :race_condition_ttl.
        Rails.cache.fetch(
          "variant_query-for-#{user&.id || 'no-one'}",
          race_condition_ttl: 10.seconds,
          expires_in: 10.minutes,
        ) { rand }
      end

      # Responsible for transforming the :select_fragment, :cases, and :fallback into a SQL fragment
      # that we can use to multiply with the other SQL fragments.
      #
      # @param select_fragment [String]
      # @param cases [Array<Array<#to_i, #to_f>>]
      # @param fallback [#to_f]
      def build_score_element_from(select_fragment:, cases:, fallback:)
        values = []
        # I would love to sanitize this, but alas, we must trust this clause.
        text = "(CASE #{select_fragment}"
        cases.each do |value, factor|
          text += "\nWHEN ? THEN ?"
          values << value.to_i
          values << factor.to_f
        end
        text += "\nELSE ? END)"
        values << fallback.to_f
        values.unshift(text)

        Article.sanitize_sql_array(values)
      end
    end
  end
end
