module Articles
  module Feeds
    # @api private
    #
    # This is an experimental object that we're refining to be a
    # competetor to the existing feed strategies.
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
      # A scoring method should be a SQL fragement that produces a
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
      # - clause: The SQL clause statement; note: there exists a
      #           coupling between the clause and the SQL fragments
      #           that join the various tables.  Also, under no
      #           circumstances should you allow any user value for
      #           this, as it is not something we can sanitize.
      #
      # - cases: An Array of Arrays, the first value is what matches
      #          the clause, the second value is the multiplicative
      #          factor.
      #
      # - fallback: When no case is matched use this factor.
      #
      # - requires_user: Does this scoring method require a given
      #                  user.  If not, don't use it if we don't have
      #                  a nil user.
      SCORING_METHOD_CONFIGURATIONS = {
        # Weight to give based on the age of the article.
        daily_decay_factor: {
          clause: "(current_date - published_at::date)",
          cases: [
            [0, 1], [1, 0.95], [2, 0.9],
            [3, 0.85], [4, 0.8], [5, 0.75],
            [6, 0.7], [7, 0.65], [8, 0.6],
            [9, 0.55], [10, 0.5], [11, 0.4],
            [12, 0.3], [13, 0.2], [14, 0.1]
          ],
          fallback: 0.001,
          requires_user: false
        },
        # Weight to give for the number of comments on the article
        # from other users that the given user follows.
        comment_count_by_those_followed_factor: {
          clause: "COUNT(comments_by_followed.id)",
          cases: [[0, 0.95], [1, 0.98], [2, 0.99]],
          fallback: 0.93,
          requires_user: true
        },
        # Weight to give to the number of comments on the article.
        comments_count_factor: {
          clause: "articles.comments_count",
          cases: [[0, 0.9], [1, 0.94], [2, 0.95], [3, 0.98], [4, 0.999]],
          fallback: 1,
          requires_user: false
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
          requires_user: true
        },
        # Weight to give when the given user follows the article's
        # author.
        following_author_factor: {
          clause: "COUNT(followed_user.follower_id)",
          cases: [[0, 0.8], [1, 1]],
          fallback: 1,
          requires_user: true
        },
        # Weight to give to the when the given user follows the
        # article's organization.
        following_org_factor: {
          clause: "COUNT(followed_org.follower_id)",
          cases: [[0, 0.95], [1, 1]],
          fallback: 1,
          requires_user: true
        },
        # Weight to give an article based on it's most recent comment.
        latest_comment_factor: {
          clause: "(current_date - MAX(comments.created_at)::date)",
          cases: [[0, 1], [1, 0.9988]],
          fallback: 0.988,
          requires_user: false
        },
        # Weight to give for the number of intersecting tags the given
        # user follows and the article has.
        matching_tags_factor: {
          clause: "COUNT(followed_tags.follower_id)",
          cases: [[0, 0.4], [1, 0.9]],
          fallback: 1,
          requires_user: true
        },
        # Weight to give for the number of reactions on the article.
        reactions_factor: {
          clause: "articles.reactions_count",
          cases: [[0, 0.9988], [1, 0.9988], [2, 0.9988], [3, 0.9988]],
          fallback: 1,
          requires_user: false
        },
        # Weight to give based on spaminess of the article.
        spaminess_factor: {
          clause: "articles.spaminess_rating",
          cases: [[0, 1]],
          fallback: 0,
          requires_user: false
        }
      }.freeze

      DEFAULT_USER_EXPERIENCE_LEVEL = 5

      # @param user [User] who are we querying for?
      # @param number_of_articles [Integer] how many articles are we
      #   returning
      # @param page [Integer] what is the pagination page
      # @param tag [String, nil] this isn't implemented in other feeds
      #   so we'll see
      # @param config [Hash<Symbol, Object>] a list of configurations,
      #   see {#initialize} implementation details.
      # @option config [Array<Symbol>] :scoring_configs
      #   allows for you to configure which methods you want to use.
      #   This is most relevant when running A/B testing.
      # @option config [Integer] :most_number_of_days_to_consider
      #   defines the oldest published date that we'll consider.
      #
      # @todo I envision that we will tweak the factors we choose, so
      #   those will likely need some kind of structured consideration.
      def initialize(user: nil, number_of_articles: 50, page: 1, tag: nil, **config)
        @user = user
        @number_of_articles = number_of_articles.to_i
        @page = page.to_i
        # TODO: The tag parameter is vestigial, there's no logic around this value.
        @tag = tag
        @default_user_experience_level = config.fetch(:default_user_experience_level) { DEFAULT_USER_EXPERIENCE_LEVEL }
        @oldest_published_at = determine_oldest_published_at(
          user: @user,
          most_number_of_days_to_consider: config.fetch(:most_number_of_days_to_consider, 31),
        )
        @scoring_configs = config.fetch(:scoring_configs) { default_scoring_configs }
        configure!(scoring_configs: @scoring_configs)
      end

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
      # @param feature_requires_image [Boolean] select only articles that have
      #        a main image.
      # @param limit [Integer] the number of records to return
      # @param offset [Integer] start the paging window at the given offset
      # @param omit_article_ids [Array] don't include these articles in the search results
      #
      # @return ActiveRecord::Relation for Article
      # rubocop:disable Layout/LineLength
      def call(only_featured: false, feature_requires_image: false, limit: default_limit, offset: default_offset, omit_article_ids: [])
        unsanitized_sub_sql = if @user.nil?
                                [
                                  sql_sub_query_for_nil_user(
                                    only_featured: only_featured,
                                    feature_requires_image: feature_requires_image,
                                    limit: limit,
                                    offset: offset,
                                    omit_article_ids: omit_article_ids,
                                  ),
                                  {
                                    oldest_published_at: @oldest_published_at,
                                    omit_article_ids: omit_article_ids
                                  },
                                ]
                              else
                                [
                                  sql_sub_query_for_existing_user(
                                    only_featured: only_featured,
                                    feature_requires_image: feature_requires_image,
                                    limit: limit,
                                    offset: offset,
                                    omit_article_ids: omit_article_ids,
                                  ),
                                  {
                                    user_id: @user.id,
                                    default_user_experience_level: @default_user_experience_level.to_i,
                                    oldest_published_at: @oldest_published_at,
                                    omit_article_ids: omit_article_ids
                                  },
                                ]
                              end

        # This sub-query allows us to take the hard work of the
        # hand-coded unsanitized sql and create a sub-query that we
        # can use to help ensure that we can use all of the
        # ActiveRecord goodness of scopes (e.g.,
        # limited_column_select) and eager includes.
        Article.where(
          Article.arel_table[:id].in(
            Arel.sql(
              Article.sanitize_sql(unsanitized_sub_sql),
            ),
          ),
        ).limited_column_select.includes(top_comments: :user).order(published_at: :desc)
      end
      # rubocop:enable Layout/LineLength

      # Provided as a means to align interfaces with existing feeds.
      #
      # @note I really dislike this method name as it is opaque on
      #       it's purpose.
      alias more_comments_minimal_weight_randomized call

      # The featured story should be the article that:
      #
      # - has the highest relevance score for the nil_user version
      # - has `featured = true`
      # - (OPTIONALLY) has a main image
      #
      # The other articles should use the nil_user version and require
      # the `featured = true` attribute.  In my envisioned
      # implementation, the pagination would omit the featured story.
      #
      # @param feature_requires_image [Boolean] do we mandate that the
      #        featured story/stories require an image?
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
      # @note There are requests to allow for the featured article to
      #       NOT require a main image.  We're still talking through
      #       what that means.
      # @note including the ** operator to mirror the method interface
      #       of the other feed strategies.
      def featured_story_and_default_home_feed(feature_requires_image: true, **)
        # We could parameterize this, but callers would need to
        # consider the impact of that decision, and it would break the
        # current contract.
        number_of_featured_stories = 1
        featured_story = call(
          feature_requires_image: feature_requires_image,
          only_featured: true,
          limit: number_of_featured_stories,
          offset: 0,
        ).first
        articles = call(
          feature_requires_image: feature_requires_image,
          only_featured: true,
          # Make sure that we don't include the featured_story
          omit_article_ids: [featured_story&.id],
        )
        [featured_story, articles]
      end

      # @note In the LargeForemExperimental implementation, the
      #       default home feed omits the featured story.  In this
      #       case, I don't want to do that.  Instead, I want to see
      #       how this behaves.
      def default_home_feed(feature_requires_image: true, **)
        call(
          feature_requires_image: feature_requires_image,
          only_featured: true,
        )
      end

      private

      # The sql statement for selecting based on relevance scores that
      # are for nil users.
      def sql_sub_query_for_nil_user(only_featured:, feature_requires_image:, limit:, offset:, omit_article_ids:)
        where_clause = build_sql_with_where_clauses(
          only_featured: only_featured,
          feature_requires_image: feature_requires_image,
          omit_article_ids: omit_article_ids,
        )
        <<~THE_SQL_STATEMENT
          SELECT articles.id
          FROM articles
          LEFT OUTER JOIN comments
            ON comments.commentable_id = articles.id
              AND comments.commentable_type = 'Article'
          WHERE #{where_clause}
          GROUP BY articles.id
          ORDER BY (#{relevance_score_components_as_sql}) DESC,
            articles.published_at DESC
          #{offset_and_limit_clause(offset: offset, limit: limit)}
        THE_SQL_STATEMENT
      end

      # The sql statement for selecting based on relevance scores that
      # are user required.
      def sql_sub_query_for_existing_user(only_featured:, feature_requires_image:, limit:, offset:, omit_article_ids:)
        where_clause = build_sql_with_where_clauses(
          only_featured: only_featured,
          feature_requires_image: feature_requires_image,
          omit_article_ids: omit_article_ids,
        )
        <<~THE_SQL_STATEMENT
          SELECT articles.id
          FROM articles
          LEFT OUTER JOIN taggings
            ON taggings.taggable_id = articles.id
              AND taggable_type = 'Article'
          INNER JOIN tags
            ON taggings.tag_id = tags.id
          LEFT OUTER JOIN follows AS followed_tags
            ON tags.id = followed_tags.followable_id
              AND followed_tags.followable_type = 'ActsAsTaggableOn::Tag'
              AND followed_tags.follower_type = 'User'
              AND followed_tags.follower_id = :user_id
          LEFT OUTER JOIN follows AS followed_user
            ON articles.user_id = followed_user.followable_id
              AND followed_user.followable_type = 'User'
              AND followed_user.follower_id = :user_id
              AND followed_user.follower_type = 'User'
          LEFT OUTER JOIN follows AS followed_org
            ON articles.organization_id = followed_org.followable_id
              AND followed_org.followable_type = 'Organization'
              AND followed_org.follower_id = :user_id
              AND followed_org.follower_type = 'User'
          LEFT OUTER JOIN comments AS comments_by_followed
            ON comments_by_followed.commentable_id = articles.id
              AND comments_by_followed.commentable_type = 'Article'
              AND followed_user.followable_id = comments_by_followed.user_id
              AND followed_user.followable_type = 'User'
          LEFT OUTER JOIN user_blocks
            ON user_blocks.blocked_id = articles.user_id
              AND user_blocks.blocked_id IS NULL
              AND user_blocks.blocker_id = :user_id
          LEFT OUTER JOIN comments
            ON comments.commentable_id = articles.id
              AND comments.commentable_type = 'Article'
          WHERE #{where_clause}
          GROUP BY articles.id
          ORDER BY (#{relevance_score_components_as_sql}) DESC,
            articles.published_at DESC
            #{offset_and_limit_clause(offset: offset, limit: limit)}
        THE_SQL_STATEMENT
      end

      # @todo Do we want to favor published at for scoping, or do we
      #       want to consider `articles.last_comment_at`.  If we do,
      #       we must remember to add an index to that field.
      def build_sql_with_where_clauses(only_featured:, feature_requires_image:, omit_article_ids:)
        where_clauses = "articles.published = true AND articles.published_at > :oldest_published_at"
        where_clauses += " AND articles.id NOT IN (:omit_article_ids)" unless omit_article_ids.empty?
        where_clauses += " AND articles.featured = true" if only_featured
        where_clauses += " AND articles.main_image IS NOT NULL" if feature_requires_image
        where_clauses
      end

      def offset_and_limit_clause(offset:, limit:)
        if offset.to_i.positive?
          Article.sanitize_sql_array(["OFFSET ? LIMIT ?", offset, limit])
        else
          Article.sanitize_sql_array(["LIMIT ?", limit])
        end
      end

      def determine_oldest_published_at(user:, most_number_of_days_to_consider: 31)
        user&.page_views&.second_to_last&.created_at || most_number_of_days_to_consider.days.ago
      end

      # We multiply the relevance score components together.
      def relevance_score_components_as_sql
        @relevance_score_components.join(" * ")
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
        @relevance_score_components = []

        # We looping through the possible scoring method
        # configurations, we're only accepting those as valid
        # configurations.
        SCORING_METHOD_CONFIGURATIONS.each_pair do |valid_method_name, default_config|
          # Don't attempt to use this factor if we don't have user.
          next if default_config.fetch(:requires_user) && @user.nil?

          # Ensure that we're only using a scoring configuration that
          # the caller provided.
          next unless scoring_configs.key?(valid_method_name)

          scoring_config = scoring_configs.fetch(valid_method_name)

          # If the caller didn't provide a hash for this scoring configuration,
          # then we'll use the default configuration.
          scoring_config = default_config unless scoring_config.is_a?(Hash)

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
        end
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
