module Articles
  class HandleSpamWorker
    include Sidekiq::Job

    sidekiq_options queue: :high_priority

    def perform(article_id)
      article = Article.find_by(id: article_id)
      return unless article

      # Always run spam handling and score update
      Spam::Handler.handle_article!(article: article)
      article.reload.update_score

      # Only enhance if clickbait score is 0 (not already processed) and score is >= 0 (good quality after spam check)
      return unless article.clickbait_score.zero? && article.score >= 0

      enhance_article(article)
    end

    private

    def enhance_article(article)
      # Create AI client for dependency injection
      ai_client = Ai::Base.new
      enhancer = Ai::ArticleEnhancer.new(article, ai_client: ai_client)

      # Calculate and update clickbait score
      clickbait_score = enhancer.calculate_clickbait_score
      article.update_column(:clickbait_score, clickbait_score)

      # Generate and apply tags if article has no tags and meets criteria
      if should_generate_tags?(article, clickbait_score)
        suggested_tags = enhancer.generate_tags
        apply_tags_to_article(article, suggested_tags) if suggested_tags.any?
      end
    rescue StandardError => e
      Rails.logger.error("Article enhancement failed for article #{article.id}: #{e}")
    end

    def should_generate_tags?(article, clickbait_score)
      article.cached_tag_list.blank? &&
        article.score >= 0 &&
        clickbait_score < 0.6
    end

    def apply_tags_to_article(article, tag_names)
      # Validate that all suggested tags exist and are supported
      valid_tags = Tag.supported.where(name: tag_names).pluck(:name)

      if valid_tags.any?
        # Apply tags to article
        article.tag_list = valid_tags
        article.cached_tag_list = valid_tags.join(", ")
        article.save

        Rails.logger.info("Applied tags #{valid_tags.join(', ')} to article #{article.id}")
      else
        Rails.logger.warn("No valid tags found from suggestions #{tag_names.join(', ')} for article #{article.id}")
      end
    end
  end
end
