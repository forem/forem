module DataUpdateScripts
  class FixNegativeReactionCounters
    BATCH_SIZE = 100

    def run
      Rails.logger.info("[FixNegativeReactionCounters] Starting negative counter fix...")

      articles_fixed = fix_reactable_counters(Article, "articles")
      comments_fixed = fix_reactable_counters(Comment, "comments")

      # Also fix previous_public_reactions_count on articles
      fix_previous_public_reactions_count

      total_fixed = articles_fixed + comments_fixed
      Rails.logger.info("[FixNegativeReactionCounters] Completed - fixed #{total_fixed} total records")

      # Verify no negative values remain
      verify_no_negative_values_remain
    end

    private

    def fix_reactable_counters(model, model_name)
      Rails.logger.info("[FixNegativeReactionCounters] Processing #{model_name}...")

      scope = model.where("public_reactions_count < 0")
      total_count = scope.count

      if total_count.zero?
        Rails.logger.info("[FixNegativeReactionCounters] No #{model_name} with negative counts found")
        return 0
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
      fixed_count
    end

    def fix_previous_public_reactions_count
      Rails.logger.info("[FixNegativeReactionCounters] Processing previous_public_reactions_count on articles...")

      # Fix previous_public_reactions_count by setting to 0 if negative
      # (this is a snapshot value, not a live counter, so 0 is safe)
      count = Article.where("previous_public_reactions_count < 0").count

      if count.zero?
        Rails.logger.info("[FixNegativeReactionCounters] No articles with negative previous_public_reactions_count")
        return
      end

      Article.where("previous_public_reactions_count < 0").update_all(previous_public_reactions_count: 0)
      Rails.logger.info("[FixNegativeReactionCounters] Reset #{count} articles previous_public_reactions_count to 0")
    end

    def verify_no_negative_values_remain
      articles_remaining = Article.where("public_reactions_count < 0 OR previous_public_reactions_count < 0").count
      comments_remaining = Comment.where("public_reactions_count < 0").count

      if articles_remaining.positive? || comments_remaining.positive?
        Rails.logger.warn(
          "[FixNegativeReactionCounters] WARNING: #{articles_remaining} articles and " \
          "#{comments_remaining} comments still have negative counts!",
        )
      else
        Rails.logger.info("[FixNegativeReactionCounters] Verified: no negative values remain")
      end
    end
  end
end
