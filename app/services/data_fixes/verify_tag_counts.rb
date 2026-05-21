module DataFixes
  class VerifyTagCounts
    KEY = "verify_tag_counts".freeze

    def call
      tags_table = ActsAsTaggableOn::Tag.quoted_table_name
      taggings_table = ActsAsTaggableOn::Tagging.quoted_table_name

      result = ActsAsTaggableOn::Tag.connection.select_one(<<-SQL.squish)
        SELECT
          COUNT(*) AS total,
          COUNT(*) FILTER (WHERE tags.taggings_count <> COALESCE(tc.actual_count, 0)) AS mismatched
        FROM #{tags_table} AS tags
        LEFT JOIN (
          SELECT tag_id, COUNT(*) AS actual_count
          FROM #{taggings_table}
          GROUP BY tag_id
        ) AS tc ON tc.tag_id = tags.id
      SQL

      { total: result["total"].to_i, mismatched: result["mismatched"].to_i }
    end
  end
end
