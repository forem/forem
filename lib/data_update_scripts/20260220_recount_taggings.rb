module DataUpdateScripts
  class RecountTaggings
    def up
      # The acts-as-taggable-on gem provides a built-in method to recount taggings
      # This fixes the issue where `tags.taggings_count` counters become out of sync
      # See: https://github.com/forem/forem/issues/6586
      #
      # The root cause is likely from:
      # 1. Bulk operations that bypass callbacks
      # 2. Historical bugs in older gem versions
      # 3. Race conditions or deadlocks during tagging updates
      #
      # The fix is idempotent and safe to run multiple times
      
      puts "Recounting taggings for all tags..."
      start_time = Time.current

      begin
        ActsAsTaggableOn::Tag.recount_taggings
        duration = (Time.current - start_time).round(2)
        puts "✓ Successfully recounted all taggings in #{duration}s"
      rescue => e
        puts "✗ Error recounting taggings: #{e.message}"
        raise e
      end
    end

    def down
      # This is a data correction script with no real "down" action
      # The original counts are lost, so we can't safely restore them
      puts "This data update cannot be reversed. Tag counts have been corrected based on actual taggings."
    end
  end
end

DataUpdateScripts::RecountTaggings.new.up
