module DataUpdateScripts
  class FixNegativeReactionCounters
    BATCH_SIZE = 100

    def run
      fix_reactable_counters(Article, "articles")
      fix_reactable_counters(Comment, "comments")

      Rails.logger.info("[FixNegativeReactionCounters] Completed successfully")
    end

    private

    def fix_reactable_counters(model, model_name)
      Rails.logger.info("[FixNegativeReactionCounters] Processing #{model_name}...")

      scope = model.where("public_reactions_count < 0")
      total_count = scope.count

      if total_count.zero?
        Rails.logger.info("[FixNegativeReactionCounters] No #{model_name} with negative counts found")
        return
      end

      Rails.logger.info("[FixNegativeReactionCounters] Found #{total_count} #{model_name} with negative counts")
      fixed_count = 0

      scope.find_in_batches(batch_size: BATCH_SIZE) do |batch|
        batch.each do |record|
          update_counter_efficiently(record)
          fixed_count += 1
        end

        Rails.logger.info("[FixNegativeReactionCounters] Progress: #{fixed_count}/#{total_count} #{model_name}")
      end

      Rails.logger.info("[FixNegativeReactionCounters] Fixed #{fixed_count} #{model_name}")
    end

    def update_counter_efficiently(record)
      # Use SQL to avoid race conditions and unnecessary object reloading
      correct_count = record.reactions.public_category.count
      record.class.where(id: record.id).update_all(public_reactions_count: correct_count)
    end
  end
end
