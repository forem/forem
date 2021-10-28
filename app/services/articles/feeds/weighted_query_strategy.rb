module Articles
  module Feeds
    # @api private
    #
    # This is an experimental object that we're refining to be a
    # competetor to the existing feed strategies.
    #
    # At present, there are no optimizations.  They could include:
    #
    # 1) Eager loading of objects relevant for articles in the feed.
    # 2) Is there a better query structure for these concerns?
    #
    # I've also chosen to atomize the SQL statement construction to highlight
    # how we might parameterize the various weights, or even swap out
    # multiplicative methods for additive methods.
    #
    # @note One possible short-coming is that the query does not
    #   account for the Forem's administrators.
    # @note For those considering extending this, be very mindful of
    #   SQL injection.
    class WeightedQueryStrategy
      # This constant defines the allowable relevance scoring methods.
      # A scoring method should be a SQL fragement that produces a
      # value between 0 and 1.
      POSSIBLE_SCORING_METHOD_NAMES = %i[
        base_score
        comment_count_by_those_followed_factor
        comments_count_factor
        experience_factor
        following_author_factor
        following_org_factor
        latest_comment_factor
        matching_tags_factor
        reactions_factor
        spaminess_factor
      ].freeze

      # @param user [User] who are we querying for?
      # @param number_of_articles [Integer] how many articles are we
      #   returning
      # @param page [Integer] what is the pagination page
      # @param tag [String, nil] this isn't implemented in other feeds
      #   so we'll see
      # @param config [Hash<Symbol, Object>] a list of configurations,
      #   see {#initialize} implementation details.
      # @option config [Array<Symbol>] :scoring_method_names
      #   allows for you to configure which methods you want to use.
      #   This is most relevant when running A/B testing.
      #
      # @todo I envision that we will tweak the factors we choose, so
      #   those will likely need some kind of structured consideration.
      def initialize(user: nil, number_of_articles: 50, page: 1, tag: nil, **config)
        @user = user
        @number_of_articles = number_of_articles.to_i
        @page = page
        @tag = tag
        self.scoring_method_names = config.fetch(:scoring_method_names) { default_scoring_method_names }
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
      def call
        Article.find_by_sql([the_sql_statement, { user_id: @user.id, number_of_results: @number_of_articles }])
      end

      private

      # The relevance score components speak.  Those method
      # implementations are deeply entwined with the SQL statements.
      #
      # @todo Remember to not use "SELECT articles.*" which will
      # probably mean I want to use AREL project.
      def the_sql_statement
        <<~THE_SQL_STATEMENT
          WITH top_articles AS (
            SELECT articles.id,
            (#{relevance_score_components_as_sql}) AS relevance_score
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
            LEFT OUTER JOIN comments
              ON comments.commentable_id = articles.id
                AND comments.commentable_type = 'Article'
                AND followed_user.followable_id = comments.user_id
                AND followed_user.followable_type = 'User'
            LEFT OUTER JOIN user_blocks
              ON user_blocks.blocked_id = articles.user_id
                AND user_blocks.blocked_id IS NULL
                AND user_blocks.blocker_id = :user_id
            WHERE published = true
            GROUP BY articles.id,
              articles.title,
              articles.published_at,
              articles.comments_count,
              articles.experience_level_rating,
              articles.spaminess_rating
            ORDER BY relevance_score DESC,
              articles.published_at DESC
            LIMIT :number_of_results)
          SELECT articles.*
          FROM articles
          INNER JOIN top_articles
            ON top_articles.id = articles.id
            ORDER BY articles.published_at DESC;
        THE_SQL_STATEMENT
      end

      # The current factors are as follows:
      #
      # 1. Proximity of article's experience level rating to user's experience level.
      # 2. If someone the user follows has commented on the article.
      # 3. The number of article tags that intersect with the user.
      # 4. If the user follows the article's author.
      # 5. If the user follows the article's author's organization.
      # 6. The spaminess of the article.
      def relevance_score_components_as_sql
        relevance_score_components.join(" * ")
      end

      # By default, we use the scoring methods that are possible.
      def default_scoring_method_names
        POSSIBLE_SCORING_METHOD_NAMES
      end

      # Don't allow unexpected method names, use only what's possible.
      def scoring_method_names=(values)
        @scoring_method_names = Array(values) & POSSIBLE_SCORING_METHOD_NAMES
      end
      attr_reader :scoring_method_names

      def relevance_score_components
        scoring_method_names.map { |method_name| __send__(method_name) }
      end

      # @param base_score [Integer] the starting score.  You could
      #   change this, but due to the algorithm changing this won't due
      #   all that much.  But we're naming the parameter to describe the
      #   number.
      #
      # @param daily_decay_factor [#to_f] for each day before
      #   the current date, reduce the base score by this amount.
      def base_score(base_score: 1, daily_decay_factor: 0.05)
        %((#{base_score.to_i} - (current_date - published_at::date) * #{daily_decay_factor.to_f}))
      end

      # This provides the lever for adjusting the feed to devalue
      # articles marked as spam.
      #
      # @see BlackBox#calculate_spaminess
      def spaminess_factor
        %((CASE articles.spaminess_rating
            WHEN 0 THEN 1
            ELSE 0.05 END))
      end

      # This factor addresses the differential between the user's
      # rating and the article's rating.
      #
      # @param user_experience_level [Integer] the user's self
      #   identified experience level.
      def experience_factor(user_experience_level: 5)
        %((CASE ABS(articles.experience_level_rating - #{user_experience_level.to_i})
            WHEN 0 THEN 1
            WHEN 1 THEN 0.98
            WHEN 2 THEN 0.97
            WHEN 3 THEN 0.96
            WHEN 4 THEN 0.95
            WHEN 5 THEN 0.94
            ELSE 0.93 END
            ))
      end

      # This factor addresses the concept that we want to value
      # articles in which people followed by the user commented on the
      # article.
      def comment_count_by_those_followed_factor
        %((CASE COUNT(comments.id)
            WHEN 0 THEN 0.95
            WHEN 1 THEN 0.98
            WHEN 2 THEN 0.99
            ELSE 1 END))
      end

      # Slightly nudge downward posts with older comments.
      def latest_comment_factor
        %((CASE (current_date - MAX(comments.created_at)::date)
           WHEN 0 THEN 1
           WHEN 1 THEN 0.9988
           ELSE 0.988 END))
      end

      # This factor addresses the idea that for a given article's
      # tags, the more that those tags intersect with the given user's
      # followed tags, the more weight we want to give to the article.
      def matching_tags_factor
        %((CASE COUNT(followed_tags.follower_id)
            WHEN 0 THEN 0.4
            WHEN 1 THEN 0.9
            ELSE 1 END))
      end

      # This factor gives weight to the user following the article's
      # author.
      def following_author_factor
        %((CASE COUNT(followed_user.follower_id)
            WHEN 0 THEN 0.8
            WHEN 1 THEN 1
            ELSE 1 END))
      end

      # The more comments, the more weight to give to the article.
      def comments_count_factor
        %((CASE articles.comments_count
            WHEN 0 THEN 0.9
            WHEN 1 THEN 0.94
            WHEN 2 THEN 0.95
            WHEN 3 THEN 0.98
            WHEN 4 THEN 0.999
            ELSE 1 END))
      end

      # Introducing just the tiniest decay if there aren't a lot of reactions.
      def reactions_factor
        %((CASE articles.reactions_count
           WHEN 0 THEN 0.9988
           WHEN 1 THEN 0.9988
           WHEN 2 THEN 0.9988
           WHEN 3 THEN 0.9988
           ELSE 1 END))
      end

      # This factor gives weight to the user following the article's
      # author's organization.
      def following_org_factor
        %((CASE COUNT(followed_org.follower_id)
            WHEN 0 THEN 0.95
            WHEN 1 THEN 1
            ELSE 1 END))
      end
    end
  end
end
