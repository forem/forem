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

      # Process in batches to avoid N+1 queries
      # Uses Reactable.sync_reactions_count_for_batch for efficient batch updates
      scope.find_in_batches(batch_size: BATCH_SIZE) do |batch|
        model.sync_reactions_count_for_batch(batch)
        fixed_count += batch.size

        Rails.logger.info("[FixNegativeReactionCounters] Progress: #{fixed_count}/#{total_count} #{model_name}")
      end

      Rails.logger.info("[FixNegativeReactionCounters] Fixed #{fixed_count} #{model_name}")
    end
  end
end
