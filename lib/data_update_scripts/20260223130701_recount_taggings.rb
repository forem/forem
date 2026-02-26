module DataUpdateScripts
  class RecountTaggings
    def run
      # Fixes tag taggings_count desync (https://github.com/forem/forem/issues/6586)
      # Idempotent and safe to run multiple times

      puts "Recounting taggings for all tags..."
      start_time = Time.current

      begin
        connection      = ActsAsTaggableOn::Tag.connection
        tags_table      = ActsAsTaggableOn::Tag.quoted_table_name
        taggings_table  = ActsAsTaggableOn::Tagging.quoted_table_name

        # First, set all taggings_count values to 0 so tags without taggings are correctly zeroed.
        connection.execute("UPDATE #{tags_table} SET taggings_count = 0")

        # Then, update taggings_count based on the actual number of taggings per tag.
        update_sql = <<-SQL.squish
          UPDATE #{tags_table} AS tags
          SET taggings_count = tag_counts.tag_count
          FROM (
            SELECT tag_id, COUNT(*) AS tag_count
            FROM #{taggings_table}
            GROUP BY tag_id
          ) AS tag_counts
          WHERE tags.id = tag_counts.tag_id
        SQL

        connection.execute(update_sql)
        duration = (Time.current - start_time).round(2)
        puts "✓ Successfully recounted all taggings in #{duration}s"
      rescue => e
        puts "✗ Error recounting taggings: #{e.message}"
        raise e
      end
    end
  end
end
