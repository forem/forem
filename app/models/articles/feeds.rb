module Articles
  module Feeds
    # The default number of days old that an article can be for us
    # to consider it in the relevance feed.
    #
    # @note I believe that it is likely we would extract this constant
    #       into an administrative setting.  Hence, I want to keep it
    #       a scalar.
    DEFAULT_DAYS_SINCE_PUBLISHED = 7

    # @note I believe that it is likely we would extract this constant
    #       into an administrative setting.  Hence, I want to keep it
    #       a scalar to ease the implementation details of the admin
    #       setting.
    NUMBER_OF_HOURS_TO_OFFSET_USERS_LATEST_ARTICLE_VIEWS = 18

    DEFAULT_USER_EXPERIENCE_LEVEL = 5
    DEFAULT_NEGATIVE_REACTION_THRESHOLD = -10
    DEFAULT_POSITIVE_REACTION_THRESHOLD = 10

    # @api private
    #
    # This method helps answer the question: What are the articles
    # that I should consider as new for the given user?  This method
    # provides a date by which to filter out "stale to the user"
    # articles.
    #
    # @note Do we need to continue using this method?  It's part of
    #       the hot story grab experiment that we ran with the
    #       Article::Feeds::LargeForemExperimental, but may not be
    #       relevant.
    #
    # @param user [User]
    # @param days_since_published [Integer] if someone
    #        hasn't viewed any articles, give them things from the
    #        database seeds.
    #
    # @return [ActiveSupport::TimeWithZone]
    #
    # @note the days_since_published is something carried
    #       over from the LargeForemExperimental and may not be
    #       relevant given that we have the :daily_decay.
    #       However, this further limitation based on a user's
    #       second most recent page view helps further winnow down
    #       the result set.
    def self.oldest_published_at_to_consider_for(user:, days_since_published: DEFAULT_DAYS_SINCE_PUBLISHED)
      time_of_second_latest_page_view = user&.page_views&.second_to_last&.created_at
      return days_since_published.days.ago unless time_of_second_latest_page_view

      time_of_second_latest_page_view - NUMBER_OF_HOURS_TO_OFFSET_USERS_LATEST_ARTICLE_VIEWS.hours
    end

    # Get the properly configured feed for the given user (and other parameters).
    #
    # @param controller [ApplicationController] used to retrieve the field_test variant
    # @param user [User, NilClass] used to retrieve the variant and how we query the articles
    # @param number_of_articles [Integer] the pagination page size
    # @param page [Integer] the page on which to start pagination
    # @param tag [NilClass, String] not used but carried forward for interface conformance
    #
    # @return [Articles::Feeds::VariantQuery]
    def self.feed_for(controller:, user:, number_of_articles:, page:, tag:)
      variant = AbExperiment.get_feed_variant_for(controller: controller, user: user)

      VariantQuery.build_for(
        variant: variant,
        user: user,
        number_of_articles: number_of_articles,
        page: page,
        tag: tag,
      )
    end

    # The available feed levers for this Forem instance.
    #
    # @return [Articles::Feeds::LeverCatalogBuilder]
    def self.lever_catalog
      LEVER_CATALOG
    end

    # rubocop:disable Metrics/BlockLength
    # The available levers for this forem instance.
    LEVER_CATALOG = LeverCatalogBuilder.new do
      order_by_lever(:relevancy_score_and_publication_date,
                     label: "Order by highest calculated relevancy score then latest published at time.",
                     order_by_fragment: "article_relevancies.relevancy_score DESC, articles.published_at DESC")

      order_by_lever(:final_order_by_random_weighted_to_score,
                     label: "Order by conflating a random number and the score (see forem/forem#16128)",
                     order_by_fragment: "article_relevancies.randomized_value " \
                                        "^ (1.0 / greatest(articles.score, 0.1)) DESC")

      order_by_lever(:published_at_with_randomization_favoring_public_reactions,
                     label: "Favor recent articles with more reactions, " \
                            "but apply randomness to mitigate stagnation.",
                     order_by_fragment: "(cast(extract(epoch FROM published_at) as integer)) * " \
                                        "(article_relevancies.randomized_value ^ (1.0 / " \
                                        "greatest(0.1, ln(1 + greatest(0, public_reactions_count))))) DESC")

      order_by_lever(:last_comment_at_with_randomization_favoring_public_reactions,
                     label: "Favor articles with recent comments and more reactions, " \
                            "but apply randomness to mitigate stagnation.",
                     order_by_fragment: "(cast(extract(epoch FROM last_comment_at) as integer)) * " \
                                        "(article_relevancies.randomized_value ^ (1.0 / " \
                                        "greatest(0.1, ln(1 + greatest(0, public_reactions_count))))) DESC")

      order_by_lever(:random_pick_of_which_date_to_use_with_randomization_favoring_public_reactions,
                     label: "Favor articles with recent comments or published at and more reactions, " \
                            "but apply randomness to mitigate stagnation.",
                     order_by_fragment: "(cast(extract(epoch FROM " \
                                        "(CASE WHEN RANDOM() > 0.5 THEN published_at ELSE last_comment_at END)) " \
                                        "as integer)) * " \
                                        "(article_relevancies.randomized_value ^ (1.0 / " \
                                        "greatest(0.1, ln(1 + greatest(0, public_reactions_count))))) DESC")

      relevancy_lever(:comments_count_by_those_followed,
                      label: "Weight to give for the number of comments on the article from other users" \
                             "that the given user follows.",
                      range: "[0..∞)",
                      user_required: true,
                      select_fragment: "COUNT(comments_by_followed.id)",
                      joins_fragments: ["LEFT OUTER JOIN follows AS followed_user
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
                                            AND comments_by_followed.created_at > :oldest_published_at"])

      relevancy_lever(:comments_count,
                      label: "Weight to give to the number of comments on the article.",
                      range: "[0..∞)",
                      user_required: false,
                      select_fragment: "articles.comments_count",
                      group_by_fragment: "articles.comments_count")

      relevancy_lever(:comments_score,
                      label: "Weight given based on sum of comment scores of an article.",
                      range: "[0..∞)",
                      user_required: false,
                      select_fragment: "SUM(
                        CASE
                          WHEN comments.score is null then 0
                          ELSE comments.score
                        END)",
                      joins_fragments: ["LEFT OUTER JOIN comments
                        ON comments.commentable_id = articles.id
                          AND comments.commentable_type = 'Article'
                          AND comments.deleted = false"])

      relevancy_lever(:daily_decay,
                      label: "Weight given based on the relative age of the article",
                      range: "[0..∞)",
                      user_required: true,
                      select_fragment: "(current_date - articles.published_at::date)",
                      group_by_fragment: "articles.published_at")

      relevancy_lever(:experience,
                      label: "Weight to give based on the difference between experience level of the " \
                             "article and given user.",
                      range: "[0..∞)",
                      user_required: true,
                      select_fragment: "ROUND(ABS(articles.experience_level_rating - (SELECT
                                          (CASE
                                             WHEN experience_level IS NULL THEN :default_user_experience_level
                                             ELSE experience_level END ) AS user_experience_level
                                          FROM users_settings WHERE users_settings.user_id = :user_id)))",
                      group_by_fragment: "articles.experience_level_rating",
                      query_parameter_names: [:default_user_experience_level])

      relevancy_lever(:featured_article,
                      label: "Weight to give for feature or unfeatured articles.  1 is featured.",
                      user_required: false,
                      range: "[0..1]",
                      select_fragment: "(CASE articles.featured WHEN true THEN 1 ELSE 0 END)",
                      group_by_fragment: "articles.featured")

      relevancy_lever(:following_author,
                      label: "Weight to give when the given user follows the article's author." \
                             "1 is followed, 0 is not followed.",
                      range: "[0..1]",
                      user_required: true,
                      select_fragment: "COUNT(followed_user.follower_id)",
                      joins_fragments: ["LEFT OUTER JOIN follows AS followed_user
                                          ON articles.user_id = followed_user.followable_id
                                            AND followed_user.followable_type = 'User'
                                            AND followed_user.follower_id = :user_id
                                            AND followed_user.follower_type = 'User'"])

      relevancy_lever(:following_org,
                      label: "Weight to give to the when the given user follows the article's organization." \
                             "1 is followed, 0 is not followed.",
                      range: "[0..1]",
                      user_required: true,
                      select_fragment: "COUNT(followed_org.follower_id)",
                      joins_fragments: ["LEFT OUTER JOIN follows AS followed_org
                                          ON articles.organization_id = followed_org.followable_id
                                            AND followed_org.followable_type = 'Organization'
                                            AND followed_org.follower_id = :user_id
                                            AND followed_org.follower_type = 'User'"])

      relevancy_lever(:latest_comment,
                      label: "Weight to give an article based on it's most recent comment.",
                      range: "[0..∞)",
                      user_required: false,
                      select_fragment: "(current_date - MAX(comments.created_at)::date)",
                      joins_fragments: ["LEFT OUTER JOIN comments
                                          ON comments.commentable_id = articles.id
                                            AND comments.commentable_type = 'Article'
                                            AND comments.deleted = false
                                            AND comments.created_at > :oldest_published_at"])

      relevancy_lever(:matching_negative_tags_intersection_count,
                      label: "Weight to give the number of intersecting tags of the article and " \
                             "user negative follows",
                      range: "[0..4]",
                      user_required: true,
                      select_fragment: "COUNT(negative_followed_tags.id)",
                      joins_fragments: ["LEFT OUTER JOIN taggings
                                         ON taggings.taggable_id = articles.id
                                           AND taggable_type = 'Article'",
                                        "INNER JOIN tags
                                         ON taggings.tag_id = tags.id",
                                        "LEFT OUTER JOIN follows AS negative_followed_tags
                                         ON tags.id = negative_followed_tags.followable_id
                                           AND negative_followed_tags.followable_type = 'ActsAsTaggableOn::Tag'
                                           AND negative_followed_tags.follower_type = 'User'
                                           AND negative_followed_tags.follower_id = :user_id
                                           AND negative_followed_tags.explicit_points < 0"])

      relevancy_lever(:matching_negative_tags_intersection_points,
                      label: "Weight to give for the sum points of the intersecting tags of the article and " \
                             "user positive follows.",
                      user_required: true,
                      range: "[-10..0]",
                      select_fragment: "LEAST(-10.0, SUM(followed_tags.points))::integer",
                      joins_fragments: ["LEFT OUTER JOIN taggings
                                         ON taggings.taggable_id = articles.id
                                           AND taggable_type = 'Article'",
                                        "INNER JOIN tags
                                         ON taggings.tag_id = tags.id",
                                        "LEFT OUTER JOIN follows AS followed_tags
                                         ON tags.id = followed_tags.followable_id
                                           AND followed_tags.followable_type = 'ActsAsTaggableOn::Tag'
                                           AND followed_tags.follower_type = 'User'
                                           AND followed_tags.follower_id = :user_id
                                           AND followed_tags.explicit_points < 0"])

      relevancy_lever(:matching_positive_tags_intersection_count,
                      label: "Weight to give for number of the intersecting tags of the article and " \
                             "user positive follows.",
                      range: "[0..4]",
                      user_required: true,
                      select_fragment: "COUNT(followed_tags.id)",
                      joins_fragments: ["LEFT OUTER JOIN taggings
                                         ON taggings.taggable_id = articles.id
                                           AND taggable_type = 'Article'",
                                        "INNER JOIN tags
                                         ON taggings.tag_id = tags.id",
                                        "LEFT OUTER JOIN follows AS followed_tags
                                         ON tags.id = followed_tags.followable_id
                                           AND followed_tags.followable_type = 'ActsAsTaggableOn::Tag'
                                           AND followed_tags.follower_type = 'User'
                                           AND followed_tags.follower_id = :user_id
                                           AND followed_tags.explicit_points >= 0"])

      relevancy_lever(:matching_positive_tags_intersection_points,
                      label: "Weight to give for the sum points of the intersecting tags of the article and " \
                             "user positive follows.",
                      user_required: true,
                      range: "[0..10]",
                      select_fragment: "LEAST(10.0, SUM(followed_tags.points))::integer",
                      joins_fragments: ["LEFT OUTER JOIN taggings
                                         ON taggings.taggable_id = articles.id
                                           AND taggable_type = 'Article'",
                                        "INNER JOIN tags
                                         ON taggings.tag_id = tags.id",
                                        "LEFT OUTER JOIN follows AS followed_tags
                                         ON tags.id = followed_tags.followable_id
                                           AND followed_tags.followable_type = 'ActsAsTaggableOn::Tag'
                                           AND followed_tags.follower_type = 'User'
                                           AND followed_tags.follower_id = :user_id
                                           AND followed_tags.explicit_points >= 0"])

      relevancy_lever(:privileged_user_reaction,
                      label: "-1 when privileged user reactions down-vote, 0 when netural, and 1 when positive.",
                      user_required: false,
                      range: "[-1..1]",
                      select_fragment: "(CASE
                 WHEN articles.privileged_users_reaction_points_sum < :negative_reaction_threshold THEN -1
                 WHEN articles.privileged_users_reaction_points_sum > :positive_reaction_threshold THEN 1
                 ELSE 0 END)",
                      group_by_fragment: "articles.privileged_users_reaction_points_sum",
                      query_parameter_names: %i[negative_reaction_threshold positive_reaction_threshold])

      # Note the symmetry of the < and >=; the smaller value is always "exclusive" and the larger value is "inclusive"
      relevancy_lever(:privileged_user_reaction_granular,
                      label: "A more granular configuration for privileged user reactions (see select_fragment)",
                      user_required: false,
                      range: "[-2..2]",
                      select_fragment: "(CASE
                 --- Very negative
                 WHEN articles.privileged_users_reaction_points_sum < :very_negative_reaction_threshold THEN -2
                 --- Negative
                 WHEN articles.privileged_users_reaction_points_sum >= :very_negative_reaction_threshold
                      AND articles.privileged_users_reaction_points_sum < :negative_reaction_threshold THEN -1
                 --- Neutral
                 WHEN articles.privileged_users_reaction_points_sum >= :negative_reaction_threshold
                      AND articles.privileged_users_reaction_points_sum < :positive_reaction_threshold THEN 0
                 --- Positive
                 WHEN articles.privileged_users_reaction_points_sum >= :positive_reaction_threshold
                      AND articles.privileged_users_reaction_points_sum < :very_positive_reaction_threshold THEN 1
                 --- Very Positive
                 WHEN articles.privileged_users_reaction_points_sum >= :very_positive_reaction_threshold THEN 2
                 ELSE 0 END)",
                      group_by_fragment: "articles.privileged_users_reaction_points_sum",
                      query_parameter_names: %i[
                        very_negative_reaction_threshold
                        negative_reaction_threshold
                        very_positive_reaction_threshold
                        positive_reaction_threshold
                      ])

      relevancy_lever(:public_reactions,
                      label: "Weight to give for the number of unicorn, heart, reading list reactions for article.",
                      range: "[0..∞)",
                      user_required: false,
                      select_fragment: "articles.public_reactions_count",
                      group_by_fragment: "articles.public_reactions_count")

      relevancy_lever(:public_reactions_score,
                      label: "Weight to give based on article.score (see article.update_score for this calculation -
                      it's a sum of the scores of reactions on an article).",
                      range: "[0..∞)",
                      user_required: false,
                      select_fragment: "articles.score",
                      group_by_fragment: "articles.score")
    end
    private_constant :LEVER_CATALOG
    # rubocop:enable Metrics/BlockLength
  end
end
