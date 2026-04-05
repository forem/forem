module Articles
  class LabelCleanupWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority

    # Maximum number of articles to process per run
    MAX_ARTICLES_PER_RUN = 150

    def perform
      # Find and select articles published in the last 48 hours but not in the last 10 minutes
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
      # Articles published in the last 48 hours but not in the last 10 minutes
      # that have automod_label of "no_moderation_label"
      # Using >= for 48.hours.ago (inclusive) and < for 10.minutes.ago (exclusive)
      forty_eight_hours_ago = 48.hours.ago
      ten_minutes_ago = 10.minutes.ago
      
      # Add a small buffer to handle precision issues
      forty_eight_hours_ago = forty_eight_hours_ago - 1.second
      
      Article.published
             .where(automod_label: "no_moderation_label")
             .where("score > -80")
             .where("published_at >= ? AND published_at < ?", forty_eight_hours_ago, ten_minutes_ago)
             .order(published_at: :desc)
             .limit(MAX_ARTICLES_PER_RUN)
    end
  end
end
