module DataUpdateScripts
  class VerifyTaggingCounts
    def run
      puts "=== Verifying taggings_count accuracy ==="

      # Preload actual tagging counts in a single query to avoid N+1
      taggings_counts = ActsAsTaggableOn::Tagging.group(:tag_id).count
      mismatched_tags = []
      
      Tag.find_each do |tag|
        actual_count = taggings_counts[tag.id] || 0
        if tag.taggings_count != actual_count
          mismatched_tags << {
            tag: tag,
            stored: tag.taggings_count,
            actual: actual_count,
            diff: actual_count - tag.taggings_count
          }
        end
      end

      puts "\nTotal tags in database: #{Tag.count}"
      puts "Tags with mismatched counts: #{mismatched_tags.length}"

      if mismatched_tags.any?
        puts "\n" + "=" * 100
        puts "Tags with mismatched counts:"
        puts "=" * 100
        puts format("%-5s %-30s %-15s %-15s %-10s", "ID", "Name", "Stored Count", "Actual Count", "Difference")
        puts "-" * 100

        mismatched_tags.each do |item|
          diff_str = item[:diff] > 0 ? "+#{item[:diff]}" : "#{item[:diff]}"
          puts format("%-5d %-30s %-15d %-15d %-10s", 
                     item[:tag].id,
                     item[:tag].name.truncate(28),
                     item[:stored],
                     item[:actual],
                     diff_str)
        end
        puts "=" * 100

        puts "\n✗ Issue CONFIRMED: #{mismatched_tags.length} tags have incorrect counts"
        puts "\nTo fix, run: rails runner 'DataUpdateScripts::RecountTaggings.new.run'"
      else
        puts "\n✓ All tag counts are accurate - no mismatches found"
      end
    end
  end
end
