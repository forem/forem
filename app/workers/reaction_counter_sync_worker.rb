class ReactionCounterSyncWorker
  include Sidekiq::Worker

  sidekiq_options queue: :low_priority, retry: 3, lock: :until_executed

  # Batch size for processing to avoid memory issues
  BATCH_SIZE = 100

  # Periodically syncs reaction counters to repair any inconsistencies.
  # This provides resilience against race conditions and counter drift.
  #
  # Run modes:
  # - perform() - Full sync of all potentially inconsistent records
  # - perform("articles") - Sync only articles
  # - perform("comments") - Sync only comments
  # - perform("sample", 1000) - Sync random sample (for regular maintenance)
  #
  # Schedule recommendation: Run "sample" mode hourly, full mode weekly
  def perform(mode = "full", limit = nil)
    Rails.logger.info("[ReactionCounterSyncWorker] Starting sync mode=#{mode} limit=#{limit}")

    case mode
    when "articles"
      sync_articles(limit)
    when "comments"
      sync_comments(limit)
    when "sample"
      sync_sample(limit || 1000)
    else
      sync_all
    end

    Rails.logger.info("[ReactionCounterSyncWorker] Sync complete")
  end

  private

  def sync_all
    sync_articles
    sync_comments
  end

  def sync_articles(limit = nil)
    scope = articles_with_inconsistent_counts
    scope = scope.limit(limit) if limit
    sync_reactables(scope, "articles")
  end

  def sync_comments(limit = nil)
    scope = comments_with_inconsistent_counts
    scope = scope.limit(limit) if limit
    sync_reactables(scope, "comments")
  end

  def sync_sample(count)
    # Random sample from both tables for regular maintenance
    articles_count = (count * 0.7).to_i
    comments_count = count - articles_count

    sync_articles(articles_count)
    sync_comments(comments_count)
  end

  def sync_reactables(scope, model_name)
    total_fixed = 0

    scope.find_in_batches(batch_size: BATCH_SIZE) do |batch|
      fixed = batch.first.class.sync_reactions_count_for_batch(batch)
      total_fixed += fixed

      Rails.logger.info("[ReactionCounterSyncWorker] Synced #{total_fixed} #{model_name}")
    end

    total_fixed
  end

  # Find articles where counter doesn't match actual reaction count
  # Uses subquery to identify mismatches efficiently
  def articles_with_inconsistent_counts
    Article
      .joins("LEFT JOIN (
        SELECT reactable_id, COUNT(*) as actual_count
        FROM reactions
        WHERE reactable_type = 'Article'
          AND category IN (#{public_category_sql})
        GROUP BY reactable_id
      ) reaction_counts ON reaction_counts.reactable_id = articles.id")
      .where("articles.public_reactions_count != COALESCE(reaction_counts.actual_count, 0)")
  end

  # Find comments where counter doesn't match actual reaction count
  def comments_with_inconsistent_counts
    Comment
      .joins("LEFT JOIN (
        SELECT reactable_id, COUNT(*) as actual_count
        FROM reactions
        WHERE reactable_type = 'Comment'
          AND category IN (#{public_category_sql})
        GROUP BY reactable_id
      ) reaction_counts ON reaction_counts.reactable_id = comments.id")
      .where("comments.public_reactions_count != COALESCE(reaction_counts.actual_count, 0)")
  end

  def public_category_sql
    # Get public reaction category slugs for the SQL query
    public_categories = ReactionCategory.public.map(&:to_s)
    public_categories.map { |c| ActiveRecord::Base.connection.quote(c) }.join(", ")
  end
end
