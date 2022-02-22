module Articles
  module Feeds
    module Configs
      class TinyDancer
        QUERY_CONFIG = {
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
            cases: (0..9).map { |n| [n, 0.8 + (0.02 * n)] },
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
            clause: "LEAST(10.0, SUM(followed_tags.points))::integer",
            cases: (0..9).map { |n| [n, 0.70 + (0.0303 * n)] },
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

        FINAL_ORDER_CONFIG = "articles.comments_count DESC".freeze
      end
    end
  end
end
