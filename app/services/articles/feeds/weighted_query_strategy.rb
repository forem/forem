module Articles
  module Feeds
    # @api private
    #
    # This is an experimental object that we're refining to be a
    # competitor to the existing feed strategies.
    #
    # It works to implement conceptual parity with two methods of
    # Articles::Feeds::LargeForemExperimental:
    #
    # - #default_home_feed
    # - #more_comments_minimal_weight_randomized
    #
    # What do we mean by "conceptual parity"?  Those two methods are
    # used in the two feeds controllers: StoriesController and
    # Stories::FeedsController.  And while they use some of the
    # internal tooling there's some notable subtle differences.
    #
    # Where this class differs is that it is aiming to build the feed
    # based from the given user's perspective.  Whereas the other Feed
    # algorithm starts with a list of candidates that are global to
    # the given Forem (e.g., starting the base query from the
    # `articles.score`, a volatile and swingy value that favors global
    # reactions over user desired content).
    #
    # This is not quite a chronological only feed but could be easily
    # modified to favor that.
    #
    # @note One possible short-coming is that the query does not
    #       account for the Forem's administrators.
    # @note For those considering extending this, be very mindful of
    #       SQL injection.
    class WeightedQueryStrategy
      # This constant defines the allowable relevance scoring methods.
      #
      # A scoring method should be a SQL fragment that produces a
      # value between 0 and 1.  The closer the value is to 1, the more
      # relevant the article is for the given user.  Note: the values
      # are multiplicative.  Make sure to consider if you want a 0
      # multiplier for your score.  Aspirationally, you may want to
      # think of the relevance_score as the range (0,1].  That is
      # greater than 0 and less than or equal to 1.
      #
      # In addition, as part of initialization, the caller can
      # configure each of the scoring methods :cases and :fallback.
      #
      # Each scoring method has the following keys:
      #
      # - clause: [Required] The SQL clause statement; note: there
      #           exists a coupling between the clause and the SQL
      #           fragments that join the various tables.  Also, under
      #           no circumstances should you allow any user value for
      #           this, as it is not something we can sanitize.
      #
      # - cases: [Required] An Array of Arrays, the first value is
      #          what matches the clause, the second value is the
      #          multiplicative factor.
      #
      # - fallback: [Required] When no case is matched use this
      #             factor.
      #
      # - requires_user: [Required] Does this scoring method require a
      #                  given user.  If not, don't use it if we don't
      #                  have a nil user.
      #
      # - group_by: [Optional] An SQL fragment that ensures a valid
      #             postgres statement in older versions of postgres.
      #             See
      #             https://github.com/forem/forem/pull/15240#discussion_r750392321
      #             for further sleuthing details.  When you reference
      #             a field in the clause, you likely need to include
      #             a corresponding :group_by attribute.
      #
      # - joins: [Optional] An SQL fragment that defines the join
      #          necessary to fulfill the clause of the scoring
      #          method.
      #
      # - enabled: [Optional] When false, we won't include this.  By
      #            default a scoring method is enabled.
      #
      # @note The group by clause appears necessary for postgres
      #       versions and Heroku configurations of current (as of
      #       <2021-11-16 Tue>) DEV.to installations.
      SCORING_METHOD_CONFIGURATIONS = {
        # Weight to give based on the age of the article.
        daily_decay_factor: {
          clause: "(current_date - articles.published_at::date)",
          cases: [
            [0, 1], [1, 0.99], [2, 0.985],
            [3, 0.98], [4, 0.975], [5, 0.97],
            [6, 0.965], [7, 0.96], [8, 0.955],
            [9, 0.95], [10, 0.945], [11, 0.94],
            [12, 0.935], [13, 0.93], [14, 0.925]
          ],
          fallback: 0.9,
          requires_user: false,
          group_by: "articles.published_at"
        },
        # Weight to give for the number of comments on the article
        # from other users that the given user follows.
        comment_count_by_those_followed_factor: {
          clause: "COUNT(comments_by_followed.id)",
          cases: [[0, 0.95], [1, 0.98], [2, 0.99]],
          fallback: 0.93,
          requires_user: true,
          joins: ["LEFT OUTER JOIN follows AS followed_user
            ON articles.user_id = followed_user.followable_id
              AND followed_user.followable_type = 'User'
              AND followed_user.follower_id = :user_id
              AND followed_user.follower_type = 'User'",
                  "LEFT OUTER JOIN comments AS comments_by_followed
            ON comments_by_followed.commentable_id = articles.id
              AND comments_by_followed.commentable_type = 'Article'
              AND followed_user.followable_id = comments_by_followed.user_id
              AND followed_user.followable_type = 'User'
              AND comments_by_followed.deleted = false
              AND comments_by_followed.created_at > :oldest_published_at"]
        },
        # Weight to give to the number of comments on the article.
        comments_count_factor: {
          clause: "articles.comments_count",
          cases: [[0, 0.9], [1, 0.92], [2, 0.94], [3, 0.96], [4, 0.98]],
          fallback: 1,
          requires_user: false,
          group_by: "articles.comments_count"
        },
        # Weight to give based on the difference between experience
        # level of the article and given user.
        experience_factor: {
          clause: "ROUND(ABS(articles.experience_level_rating - (SELECT
              (CASE
                 WHEN experience_level IS NULL THEN :default_user_experience_level
                 ELSE experience_level END ) AS user_experience_level
              FROM users_settings WHERE users_settings.user_id = :user_id
            )))",
          cases: [[0, 1], [1, 0.98], [2, 0.97], [3, 0.96], [4, 0.95], [5, 0.94]],
          fallback: 0.93,
          requires_user: true,
          group_by: "articles.experience_level_rating",
          enabled: false
        },
        # Weight to give for feature or unfeatured articles.
        featured_article_factor: {
          clause: "(CASE articles.featured WHEN true THEN 1 ELSE 0 END)",
          cases: [[1, 1]],
          fallback: 0.85,
          requires_user: false,
          group_by: "articles.featured",
          enabled: true
        },
        # Weight to give when the given user follows the article's
        # author.
        following_author_factor: {
          clause: "COUNT(followed_user.follower_id)",
          cases: [[0, 0.8], [1, 1]],
          fallback: 1,
          requires_user: true,
          joins: ["LEFT OUTER JOIN follows AS followed_user
            ON articles.user_id = followed_user.followable_id
              AND followed_user.followable_type = 'User'
              AND followed_user.follower_id = :user_id
              AND followed_user.follower_type = 'User'"]
        },
        # Weight to give to the when the given user follows the
        # article's organization.
        following_org_factor: {
          clause: "COUNT(followed_org.follower_id)",
          cases: [[0, 0.95], [1, 1]],
          fallback: 1,
          requires_user: true,
          joins: ["LEFT OUTER JOIN follows AS followed_org
            ON articles.organization_id = followed_org.followable_id
              AND followed_org.followable_type = 'Organization'
              AND followed_org.follower_id = :user_id
              AND followed_org.follower_type = 'User'"]
        },
        # Weight to give an article based on it's most recent comment.
        latest_comment_factor: {
          clause: "(current_date - MAX(comments.created_at)::date)",
          cases: [[0, 1], [1, 0.9988]],
          fallback: 0.988,
          requires_user: false,
          joins: ["LEFT OUTER JOIN comments
            ON comments.commentable_id = articles.id
              AND comments.commentable_type = 'Article'
              AND comments.deleted = false
              AND comments.created_at > :oldest_published_at"]
        },
        # Weight to give for the number of intersecting tags the given
        # user follows and the article has.
        matching_tags_factor: {
          clause: "COUNT(followed_tags.follower_id)",
          cases: [[0, 0.75], [1, 0.9]],
          fallback: 1,
          requires_user: true,
          joins: ["LEFT OUTER JOIN taggings
            ON taggings.taggable_id = articles.id
              AND taggable_type = 'Article'",
                  "INNER JOIN tags
              ON taggings.tag_id = tags.id",
                  "LEFT OUTER JOIN follows AS followed_tags
              ON tags.id = followed_tags.followable_id
                AND followed_tags.followable_type = 'ActsAsTaggableOn::Tag'
                AND followed_tags.follower_type = 'User'
                AND followed_tags.follower_id = :user_id
                AND followed_tags.explicit_points >= 0"]
        },
        # Weight privileged user's reactions.
        privileged_user_reaction_factor: {
          clause: "(CASE
                 WHEN articles.privileged_users_reaction_points_sum < :negative_reaction_threshold THEN -1
                 WHEN articles.privileged_users_reaction_points_sum > :positive_reaction_threshold THEN 1
                 ELSE 0 END)",
          cases: [[-1, 0.2],
                  [1, 1]],
          fallback: 0.95,
          requires_user: false,
          group_by: "articles.privileged_users_reaction_points_sum"
        },
        # Weight to give for the number of reactions on the article.
        reactions_factor: {
          clause: "articles.reactions_count",
          cases: [
            [0, 0.9988], [1, 0.9988], [2, 0.9988],
            [3, 0.9988]
          ],
          fallback: 1,
          requires_user: false,
          group_by: "articles.reactions_count"
        },
        # Weight to give based on spaminess of the article.
        spaminess_factor: {
          clause: "articles.spaminess_rating",
          cases: [[0, 1]],
          fallback: 0,
          requires_user: false,
          group_by: "articles.spaminess_rating"
        }
      }.freeze

      DEFAULT_USER_EXPERIENCE_LEVEL = 5

      DEFAULT_NEGATIVE_REACTION_THRESHOLD = -10
      DEFAULT_POSITIVE_REACTION_THRESHOLD = 10

      # @param user [User] who are we querying for?
      # @param number_of_articles [Integer] how many articles are we
      #   returning
      # @param page [Integer] what is the pagination page
      # @param tag [String, nil] this isn't implemented in other feeds
      #   so we'll see
      # @param strategy [String, "original"] pass a current a/b test in
      # @param config [Hash<Symbol, Object>] a list of configurations,
      #   see {#initialize} implementation details.
      # @option config [Array<Symbol>] :scoring_configs
      #   allows for you to configure which methods you want to use.
      #   This is most relevant when running A/B testing.
      # @option config [Integer] :negative_reaction_threshold, when
      #         the `articles.privileged_users_reaction_points_sum` is
      #         less than this amount, treat this is a negative
      #         reaction from moderators.
      # @option config [Integer] :positive_reaction_threshold when
      #         the `articles.privileged_users_reaction_points_sum` is
      #         greater than this amount, treat this is a positive
      #         reaction from moderators.
      #
      # @todo I envision that we will tweak the factors we choose, so
      #   those will likely need some kind of structured consideration.
      #
      # rubocop:disable Layout/LineLength
      def initialize(user: nil, number_of_articles: 50, page: 1, tag: nil, strategy: AbExperiment::ORIGINAL_VARIANT, **config)
        @user = user
        @number_of_articles = number_of_articles.to_i
        @page = (page || 1).to_i
        # TODO: The tag parameter is vestigial, there's no logic around this value.
        @tag = tag
        @strategy = strategy
        @default_user_experience_level = config.fetch(:default_user_experience_level) { DEFAULT_USER_EXPERIENCE_LEVEL }
        @negative_reaction_threshold = config.fetch(:negative_reaction_threshold, DEFAULT_NEGATIVE_REACTION_THRESHOLD)
        @positive_reaction_threshold = config.fetch(:positive_reaction_threshold, DEFAULT_POSITIVE_REACTION_THRESHOLD)
        @scoring_configs = config.fetch(:scoring_configs) { default_scoring_configs }
        configure!(scoring_configs: @scoring_configs)

        @oldest_published_at = Articles::Feeds.oldest_published_at_to_consider_for(
          user: @user,
          days_since_published: @days_since_published,
        )
      end
      # rubocop:enable Layout/LineLength

      # The goal of this query is to generate a list of articles that
      # are relevant to the user's interest.
      #
      # First we give a score to an article based on it's publication
      # date.  The max possible score is 1.
      #
      # Then we begin multiplying that score by numbers between 0 and
      # 1.  The closer that multiplier is to 1 the "more relevant"
      # that factor is to the user.
      #
      # @param only_featured [Boolean] select only articles that are
      #        "featured"
      # @param must_have_main_image [Boolean] select only articles
      #        that have a main image.
      # @param limit [Integer] the number of records to return
      # @param offset [Integer] start the paging window at the given offset
      # @param omit_article_ids [Array] don't include these articles
      #        in the search results
      #
      # @return ActiveRecord::Relation for Article
      #
      # @note This creates a complicated SQL query; well actually an
      #       ActiveRecord::Relation object on which you can call
      #       `to_sql`.  Which you might find helpful to see what's
      #       really going on.  A great place to do this is in the
      #       corresponding spec file.  See the example below:
      #
      # @example
      #
      #    user = User.first
      #    strategy = Articles::Feed::WeightedQueryStrategy.new(user: user)
      #    puts strategy.call.to_sql
      #
      # rubocop:disable Layout/LineLength
      def call(only_featured: false, must_have_main_image: false, limit: default_limit, offset: default_offset, omit_article_ids: [])
        repeated_query_variables = {
          negative_reaction_threshold: @negative_reaction_threshold,
          positive_reaction_threshold: @positive_reaction_threshold,
          oldest_published_at: @oldest_published_at,
          omit_article_ids: omit_article_ids,
          now: Time.current
        }
        unsanitized_sub_sql = if @user.nil?
                                [
                                  sql_sub_query_for_nil_user(
                                    only_featured: only_featured,
                                    must_have_main_image: must_have_main_image,
                                    limit: limit,
                                    offset: offset,
                                    omit_article_ids: omit_article_ids,
                                  ),
                                  repeated_query_variables,
                                ]
                              else
                                [
                                  sql_sub_query_for_existing_user(
                                    only_featured: only_featured,
                                    must_have_main_image: must_have_main_image,
                                    limit: limit,
                                    offset: offset,
                                    omit_article_ids: omit_article_ids,
                                  ),
                                  repeated_query_variables.merge({
                                                                   user_id: @user.id,
                                                                   default_user_experience_level: @default_user_experience_level.to_i
                                                                 }),
                                ]
                              end

        # This sub-query allows us to take the hard work of the
        # hand-coded unsanitized sql and create a sub-query that we
        # can use to help ensure that we can use all of the
        # ActiveRecord goodness of scopes (e.g.,
        # limited_column_select) and eager includes.
        finalized_results = Article.where(
          Article.arel_table[:id].in(
            Arel.sql(
              Article.sanitize_sql(unsanitized_sub_sql),
            ),
          ),
        ).limited_column_select.includes(top_comments: :user)
        final_order_logic(finalized_results)
      end
      # rubocop:enable Layout/LineLength

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

      alias more_comments_minimal_weight_randomized call

      # The featured story should be the article that:
      #
      # - has the highest relevance score for the nil_user version
      # - has a main image (see note below).
      #
      # The other articles should use the nil_user version and require
      # the `featured = true` attribute.  In my envisioned
      # implementation, the pagination would omit the featured story.
      #
      # @return [Array<Article, Array<Article>] a featured story
      #         Article and an array of Article objects.
      #
      # @note Per prior work, a featured story is the article that has
      #       a main image, is marked as featured (e.g., featured =
      #       true), and has the highest relevance score.  In the
      #       Articles::Feeds::LargeForemExperimental object we used
      #       the hotness_score to determine which to use.  The
      #       hotness score is most analogue to how this class
      #       calculates the relevance score when we don't have a
      #       user.
      #
      # @note There are requests to allow for the featured article to
      #       NOT require a main image.  We're still talking through
      #       what that means.  This work relates to PR #15333.
      #
      # @note including the ** operator to mirror the method interface
      #       of the other feed strategies.
      #
      # @todo In other implementations, when user's aren't signed in
      #       we favor featured stories.  But not so much that they're
      #       in the featured story.  For non-signed in users, we may
      #       want to use a completely different set of scoring
      #       methods.
      #
      # @note The logic of Articles::Feeds::FindFeaturedStory does not
      #       (at present) filter apply an `Article.featured` scope.
      #       [@jeremyf] I have reported this in
      #       https://github.com/forem/forem/issues/15613 to get clarity
      #       from product.
      def featured_story_and_default_home_feed(**)
        # NOTE: See the
        # https://github.com/forem/forem/blob/c1a3ba99ebec2e1ca220e9530c26cac7757c690b/app/services/articles/feeds/weighted_query_strategy.rb#L410-L426
        # state of the codebase for the implementation of first selecting
        # the feature story (using the same query logic) then selecting
        # the related articles.  With the below implementation, we need to
        # do antics in the upstream javascript file to remove the featured
        # file.  See the
        # https://github.com/forem/forem/blob/c1a3ba99ebec2e1ca220e9530c26cac7757c690b/app/javascript/articles/Feed.jsx#L42-L63
        # for that process.
        #
        # tl;dr - the below implementation creates additional downstream complexities.
        articles = call
        featured_story = Articles::Feeds::FindFeaturedStory.call(articles)
        [featured_story, articles]
      end

      private

      def final_order_logic(articles)
        case @strategy
        when "final_order_by_score"
          articles.order("score DESC")
        when "final_order_by_comment_score"
          articles.order("comment_score DESC")
        when "final_order_by_last_comment_at"
          articles.order("articles.last_comment_at DESC")
        when "final_order_by_random"
          articles.order("RANDOM()")
        when "final_order_by_random_weighted_to_score"
          articles.order(Arel.sql("RANDOM() ^ (1.0 / greatest(articles.score, 0.1)) DESC"))
        when "final_order_by_random_weighted_to_comment_score"
          articles.order(Arel.sql("RANDOM() ^ (1.0 / greatest(articles.comment_score, 0.1)) DESC"))
        when "final_order_by_random_weighted_to_last_comment_at"
          # rubocop:disable Layout/LineLength
          articles
            .order(Arel.sql("RANDOM() ^ (1.0 / greatest( 1, (extract(epoch from now() - articles.last_comment_at)::integer))) ASC"))
          # rubocop:enable Layout/LineLength
        else # original
          articles
        end
      end

      # Concatenate the required group by clauses.
      #
      # @return [String]
      def group_by_fields_as_sql
        @group_by_fields.join(", ")
      end

      # The sql statement for selecting based on relevance scores that
      # are for nil users.
      # rubocop:disable Layout/LineLength
      def sql_sub_query_for_nil_user(limit:, offset:, omit_article_ids:, only_featured: false, must_have_main_image: false)
        # rubocop:enable Layout/LineLength
        where_clause = build_sql_with_where_clauses(
          only_featured: only_featured,
          must_have_main_image: must_have_main_image,
          omit_article_ids: omit_article_ids,
        )
        <<~THE_SQL_STATEMENT
          SELECT articles.id
          FROM articles
          #{joins_clauses_as_sql}
          WHERE #{where_clause}
          GROUP BY articles.id
          ORDER BY (#{relevance_score_components_as_sql}) DESC,
            articles.published_at DESC
          #{offset_and_limit_clause(offset: offset, limit: limit)}
        THE_SQL_STATEMENT
      end

      # The sql statement for selecting based on relevance scores that
      # are user required.
      def sql_sub_query_for_existing_user(only_featured:, must_have_main_image:, limit:, offset:, omit_article_ids:)
        where_clause = build_sql_with_where_clauses(
          only_featured: only_featured,
          must_have_main_image: must_have_main_image,
          omit_article_ids: omit_article_ids,
        )
        <<~THE_SQL_STATEMENT
          SELECT articles.id
          FROM articles
          #{joins_clauses_as_sql}
          WHERE #{where_clause}
          GROUP BY #{group_by_fields_as_sql}
          ORDER BY (#{relevance_score_components_as_sql}) DESC,
            articles.published_at DESC
            #{offset_and_limit_clause(offset: offset, limit: limit)}
        THE_SQL_STATEMENT
      end

      # @todo Do we want to favor published at for scoping, or do we
      #       want to consider `articles.last_comment_at`.  If we do,
      #       we must remember to add an index to that field.
      def build_sql_with_where_clauses(only_featured:, must_have_main_image:, omit_article_ids:)
        where_clauses = "articles.published = true AND articles.published_at > :oldest_published_at"
        # See Articles.published scope discussion regarding the query planner
        where_clauses += " AND articles.published_at < :now"

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

      # By default, we use all of the possible scoring methods.
      def default_scoring_configs
        SCORING_METHOD_CONFIGURATIONS
      end

      # This method converts the caller provided :scoring_configs into
      # an array of SQL clause fragments.
      #
      # @param scoring_configs [Hash] the caller provided configurations.
      #
      # @see SCORING_METHOD_CONFIGURATIONS
      # @note Be mindful to guard against SQL injection!
      def configure!(scoring_configs:)
        @days_since_published = Articles::Feeds::DEFAULT_DAYS_SINCE_PUBLISHED
        @relevance_score_components = []

        # By default we always need to group by the articles.id
        # column.  And as we add scoring methods to the query, we need
        # to add additional group_by clauses based on the chosen
        # scoring method.
        @group_by_fields = ["articles.id"]

        @joins = Set.new

        unless @user.nil?
          @joins << "LEFT OUTER JOIN user_blocks
            ON user_blocks.blocked_id = articles.user_id
              AND user_blocks.blocked_id IS NULL
              AND user_blocks.blocker_id = :user_id"
        end

        # We looping through the possible scoring method
        # configurations, we're only accepting those as valid
        # configurations.
        SCORING_METHOD_CONFIGURATIONS.each_pair do |valid_method_name, default_config|
          # Don't attempt to use this factor if we don't have user.
          next if default_config.fetch(:requires_user) && @user.nil?
          # Don't proceed with this one if it's not enabled.
          next unless default_config.fetch(:enabled, true)

          # Ensure that we're only using a scoring configuration that
          # the caller provided.
          next unless scoring_configs.key?(valid_method_name)

          scoring_config = scoring_configs.fetch(valid_method_name)

          # If the caller didn't provide a hash for this scoring configuration,
          # then we'll use the default configuration.
          scoring_config = default_config unless scoring_config.is_a?(Hash)

          # Change an alement of config via a/b test strategy
          # scoring_config = inject_config_ab_test(valid_method_name, scoring_config) # Not currently in use.

          # This scoring method requires a group by clause.
          @group_by_fields << default_config[:group_by] if default_config.key?(:group_by)

          @joins += default_config[:joins] if default_config.key?(:joins)

          @relevance_score_components << build_score_element_from(
            # Under NO CIRCUMSTANCES should you trust the caller to
            # provide a valid :clause.  Don't trust them to send a
            # valid clause.  That's the path of SQL injection.
            clause: default_config.fetch(:clause),
            # We can trust the :cases and :fallback a bit more, as we
            # later cast them to integers and floats.
            cases: scoring_config.fetch(:cases),
            fallback: scoring_config.fetch(:fallback),
          )

          # Make sure that we consider all of the days for which we're
          # establishing cases and for which there is a fallback.
          if valid_method_name == :daily_decay_factor
            @days_since_published = scoring_config.fetch(:cases).count + 1
          end
        end
      end

      def inject_config_ab_test(valid_method_name, scoring_config)
        return scoring_config unless valid_method_name == :comments_count_factor # Only proceed on this one factor
        return scoring_config if @strategy == AbExperiment::ORIGINAL_VARIANT # Don't proceed if not testing new strategy

        # Rewards comment count with slightly more weight up to 10 comments.
        # Testing two case weights beyond what we currently have
        scoring_config[:cases] = if @strategy == "slightly_more_comments_count_case_weight"
                                   (0..9).map { |n| [n, 0.8 + (n / 50.0)] }
                                 else # much_more_comments_count_case_weight
                                   (0..19).map { |n| [n, 0.6 + (n / 50.0)] }
                                 end
        scoring_config
      end

      # Responsible for transforming the :clause, :cases, and
      # :fallback into a SQL fragment that we can use to multiply with
      # the other SQL fragments.
      #
      # @param clause [String]
      # @param cases [Array<Array<#to_i, #to_f>>]
      # @param fallback [#to_f]
      def build_score_element_from(clause:, cases:, fallback:)
        values = []
        # I would love to sanitize this, but alas, we must trust this
        # clause.
        text = "(CASE #{clause}"
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
