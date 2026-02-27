module DataFixes
  class FixTagCounts
    KEY = "fix_tag_counts".freeze

    def call
      connection = ActsAsTaggableOn::Tag.connection
      tags_table = ActsAsTaggableOn::Tag.quoted_table_name
      taggings_table = ActsAsTaggableOn::Tagging.quoted_table_name

      connection.execute("UPDATE #{tags_table} SET taggings_count = 0 WHERE taggings_count <> 0")

      update_sql = <<-SQL.squish
        UPDATE #{tags_table} AS tags
        SET taggings_count = tag_counts.tag_count
        FROM (
          SELECT tag_id, COUNT(*) AS tag_count
          FROM #{taggings_table}
          GROUP BY tag_id
        ) AS tag_counts
        WHERE tags.id = tag_counts.tag_id
          AND tags.taggings_count <> tag_counts.tag_count
      SQL

      connection.execute(update_sql)
    end
  end
end
