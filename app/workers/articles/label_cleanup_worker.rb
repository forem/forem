module Articles
  class LabelCleanupWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority

    # Maximum number of articles to process per run
    MAX_ARTICLES_PER_RUN = 75

    def perform
      # Find and randomly select articles published in the last 12 hours but not in the last 15 minutes
      # that have the automod_label of "no_moderation_label"
      selected_articles = find_eligible_articles

      if selected_articles.any?
        Rails.logger.info("LabelCleanupWorker: Processing #{selected_articles.size} articles with no_moderation_label")

        # Process each selected article
        selected_articles.each do |article|
          Articles::HandleSpamWorker.perform_async(article.id)
        end

        Rails.logger.info("LabelCleanupWorker: Enqueued #{selected_articles.size} HandleSpamWorker jobs")
      else
        Rails.logger.info("LabelCleanupWorker: No eligible articles found for processing")
      end
    end

    private

    def find_eligible_articles
      # Articles published in the last 12 hours but not in the last 15 minutes
      # that have automod_label of "no_moderation_label"
      # Using >= for 12.hours.ago (inclusive) and < for 15.minutes.ago (exclusive)
      twelve_hours_ago = 12.hours.ago
      fifteen_minutes_ago = 15.minutes.ago
      
      # Add a small buffer to handle precision issues
      twelve_hours_ago = twelve_hours_ago - 1.second
      
      Article.published
             .where(automod_label: "no_moderation_label")
             .where("score > -80")
             .where("published_at >= ? AND published_at < ?", twelve_hours_ago, fifteen_minutes_ago)
             .order(Arel.sql("RANDOM()"))
             .limit(MAX_ARTICLES_PER_RUN)
    end
  end
end
