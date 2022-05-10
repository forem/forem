# This query will return an array of hashes that have the following structure:
# [
#   {
#     "user_id"=>11,
#     "serialized_weeks_ago"=>"0,1,16,20",
#     "serialized_comment_counts"=>"2,2,1,3"
#   },
#   ...
# ]
#
# Each result (hash) comes with `user_id` and the data required to check for the
# Community Wellness Badge. These limitations consist of users that have at
# least 2 comments without negative reactions (thumbsdown/vomit) per week.
#
# Note: Using `connection.execute("").to_a` instead of `.find_by_sql` because
# ActiveRecord doesn't populate any other fields that aren't included in the raw
# result set, so we don't get any added value from instantiating AR objects
module Comments
  class CommunityWellnessQuery
    def self.call
      if limit_query_rollout?
        ActiveRecord::Base.connection.execute(limit_release_date_sql_query).to_a
      else
        ActiveRecord::Base.connection.execute(sql_query).to_a
      end
    end

    # We are rolling out the badge feature to consider comments posted May 1st,
    # 2022 or later. The logic here consists in checking if 33 weeks have passed
    # since May 1st, 2022. The method should return `true` if we need to
    # restrict the comment dates, and it will return `false` if we are good to
    # carry on without that restriction (i.e. it's been more than 33 weeks since
    # the rollout).
    #
    # We can officially remove this query+logic on December 19, 2022 at which
    # time we will continue to use the default query.
    #
    # Read more about this here:
    # https://github.com/forem/forem/issues/17310#issuecomment-1118554640
    def self.limit_query_rollout?
      Time.zone.parse("2022-05-01") > 33.weeks.ago
    end

    def self.sql_query
      <<~SQL
        SELECT user_id,
               /* A comma separated string of "weeks_ago" */
               array_to_string(array_agg(weeks_ago), ',') AS serialized_weeks_ago,
               /* A comma separated string of comment counts. The first value in this string happens on the week that is the first value in serialized_weeks_ago */
               array_to_string(array_agg(number_of_comments_with_positive_reaction), ',') AS serialized_comment_counts
        FROM
            (
                SELECT user_id,
                       COUNT(user_id) AS number_of_comments_with_positive_reaction,
                       /* Get the number of weeks, since today for posts */
                       trunc((extract(epoch FROM (current_timestamp- created_at))) / 604800) AS weeks_ago
                FROM comments
                INNER JOIN
                    (
                          SELECT DISTINCT reactable_id
                          FROM reactions
                          WHERE reactable_type = 'Comment'
                          AND created_at > (now() - interval '231' day)
                          EXCEPT
                          SELECT DISTINCT reactable_id
                          FROM reactions
                          WHERE reactable_type = 'Comment'
                          AND created_at > (now() - interval '231' day)
                          AND category IN ('thumbsdown', 'vomit')) AS negative_reactions
                ON comments.id = negative_reactions.reactable_id
                INNER JOIN
                    (
                          SELECT count(id) AS number_of_comments,
                                 user_id AS comment_counts_user_id
                          FROM comments
                          /* This interval filters week 1 (what we care about) */
                          WHERE created_at >= (now() - interval '14' day)
                          AND created_at <= (now() - interval '7' day)
                          GROUP BY user_id) AS comment_counts
                          ON comments.user_id = comment_counts_user_id
                          AND comment_counts.number_of_comments > 1
                          /* Don’t select anything older than 231 days ago, or 33 weeks ago */
                          WHERE created_at > (now() - interval '231' day)
                          GROUP BY user_id, weeks_ago) AS user_comment_counts_by_week
        GROUP BY user_id
      SQL
    end

    # This query is an exact copy of the `sql_query` but includes a filter that
    # forces the weeks to start counting from May 1st, 2022. This allows us to
    # rollout this badge one week at a time without human intervention.
    #
    # We can officially remove this query+logic on December 19, 2022 at which
    # time we will continue to use the default query.
    def self.limit_release_date_sql_query
      <<~SQL
        SELECT user_id,
               /* A comma separated string of "weeks_ago" */
               array_to_string(array_agg(weeks_ago), ',') AS serialized_weeks_ago,
               /* A comma separated string of comment counts. The first value in this string happens on the week that is the first value in serialized_weeks_ago */
               array_to_string(array_agg(number_of_comments_with_positive_reaction), ',') AS serialized_comment_counts
        FROM
            (
                SELECT user_id,
                       COUNT(user_id) AS number_of_comments_with_positive_reaction,
                       /* Get the number of weeks, since today for posts */
                       trunc((extract(epoch FROM (current_timestamp- created_at))) / 604800) AS weeks_ago
                FROM comments
                INNER JOIN
                    (
                          SELECT DISTINCT reactable_id
                          FROM reactions
                          WHERE reactable_type = 'Comment'
                          AND created_at > (now() - interval '231' day)
                          EXCEPT
                          SELECT DISTINCT reactable_id
                          FROM reactions
                          WHERE reactable_type = 'Comment'
                          AND created_at > (now() - interval '231' day)
                          AND category IN ('thumbsdown', 'vomit')) AS negative_reactions
                ON comments.id = negative_reactions.reactable_id
                INNER JOIN
                    (
                          SELECT count(id) AS number_of_comments,
                                 user_id AS comment_counts_user_id
                          FROM comments
                          /* This interval filters week 1 (what we care about) */
                          WHERE created_at >= (now() - interval '14' day)
                          AND created_at <= (now() - interval '7' day)
                          GROUP BY user_id) AS comment_counts
                          ON comments.user_id = comment_counts_user_id
                          AND comment_counts.number_of_comments > 1
                          /* Don’t select anything older than 231 days ago, or 33 weeks ago */
                          WHERE created_at > (now() - interval '231' day)
                          /* We will only awarded from this date forward (feature release date) */
                          AND created_at > '2022-05-01'
                          GROUP BY user_id, weeks_ago) AS user_comment_counts_by_week
        GROUP BY user_id
      SQL
    end
  end
end
