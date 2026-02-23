module DataUpdateScripts
  class RecountTaggings
    def run
      # Fixes tag taggings_count desync (https://github.com/forem/forem/issues/6586)
      # Idempotent and safe to run multiple times
      
      puts "Recounting taggings for all tags..."
      start_time = Time.current

      begin
        Tag.find_each do |tag|
          Tag.reset_counters(tag.id, :taggings)
        end
        duration = (Time.current - start_time).round(2)
        puts "✓ Successfully recounted all taggings in #{duration}s"
      rescue => e
        puts "✗ Error recounting taggings: #{e.message}"
        raise e
      end
    end
  end
end
