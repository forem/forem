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
      ActiveRecord::Base.connection.execute(sql_query).to_a
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
  end
end
