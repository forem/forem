module Articles
  # Backfills ArticleActivity rows for a batch of article_ids in one job
  # rather than enqueueing one full-recompute job per article. Used by
  # AnalyticsService when it discovers in-scope articles that don't yet have
  # a cache row, to keep dashboard requests from spiking the queue with
  # potentially thousands of jobs at once.
  class BackfillActivitiesWorker
    include Sidekiq::Job

    # Coalesce repeated requests for the same owner/scope while one is
    # already pending; the recompute is idempotent so collapsing dupes is safe.
    sidekiq_options queue: :low_priority,
                    retry: 3,
                    lock: :until_executing,
                    on_conflict: :replace

    def perform(article_ids)
      Array(article_ids).each_slice(100) do |chunk|
        existing = ArticleActivity.where(article_id: chunk).pluck(:article_id).to_set
        missing = chunk.reject { |id| existing.include?(id) }
        next if missing.empty?

        Article.where(id: missing).find_each do |article|
          activity = ArticleActivity.find_or_create_by!(article_id: article.id)
          activity.recompute_all!
        end
      end
    end
  end
end
