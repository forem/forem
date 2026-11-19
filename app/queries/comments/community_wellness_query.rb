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
    BATCH_SIZE = 200

    def self.call(batch_size: BATCH_SIZE)
      new(batch_size: batch_size).call
    end

    def initialize(batch_size: BATCH_SIZE)
      @batch_size = batch_size
    end

    def call
      user_ids = candidate_user_ids
      return [] if user_ids.empty?

      results = []
      user_ids.each_slice(batch_size) do |batch_user_ids|
        results.concat(fetch_batch_results(batch_user_ids))
      end
      results
    end

    private

    attr_reader :batch_size

    # Narrow to users who posted at least 2 comments in week 1 (7..14 days ago) before touching reactions.
    def candidate_user_ids
      sql = <<~SQL.squish
        SELECT user_id
        FROM comments
        WHERE created_at >= (now() - interval '14' day)
          AND created_at <= (now() - interval '7' day)
          AND user_id IS NOT NULL
        GROUP BY user_id
        HAVING COUNT(id) > 1
      SQL
      ActiveRecord::Base.connection.select_values(sql)
    end

    def fetch_batch_results(batch_user_ids)
      sql = ActiveRecord::Base.sanitize_sql_array([batch_sql, batch_user_ids])
      rows = ActiveRecord::Base.connection.select_all(sql).to_a
      return [] if rows.empty?

      rows.group_by { |row| row["user_id"].to_i }.map do |user_id, user_rows|
        {
          "user_id" => user_id,
          "serialized_weeks_ago" => user_rows.map { |r| r["weeks_ago"].to_i }.join(","),
          "serialized_comment_counts" => user_rows.map { |r| r["positive_count"].to_i }.join(",")
        }
      end
    end

    # Uses `index_comments_on_user_id` and `index_reactions_on_reactable_id_type_and_category`
    # instead of scanning 231 days of all Comment reactions across the whole table.
    def batch_sql
      <<~SQL.squish
        SELECT c.user_id,
               trunc((extract(epoch FROM (current_timestamp - c.created_at))) / 604800)::integer AS weeks_ago,
               COUNT(c.id)::integer AS positive_count
        FROM comments c
        WHERE c.user_id IN (?)
          AND c.created_at > (now() - interval '231' day)
          AND EXISTS (
            SELECT 1
            FROM reactions r
            WHERE r.reactable_type = 'Comment'
              AND r.reactable_id = c.id
          )
          AND NOT EXISTS (
            SELECT 1
            FROM reactions r
            WHERE r.reactable_type = 'Comment'
              AND r.reactable_id = c.id
              AND r.category IN ('thumbsdown', 'vomit')
          )
        GROUP BY c.user_id, weeks_ago
        ORDER BY c.user_id ASC, weeks_ago ASC
      SQL
    end
  end
end
