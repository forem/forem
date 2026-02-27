module DataUpdateScripts
  class RecountTaggings
    def run
      puts "Recounting taggings for all tags..."
      start_time = Time.current

      DataFixes::FixTagCounts.new.call

      duration = (Time.current - start_time).round(2)
      puts "✓ Successfully recounted all taggings in #{duration}s"
    rescue StandardError => e
      puts "✗ Error recounting taggings: #{e.message}"
      raise
    end
  end
end
