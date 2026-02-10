module Articles
  class EmbedWorker
    include Sidekiq::Job

    sidekiq_options queue: :low_priority

    def perform(article_id)
      article = Article.find_by(id: article_id)
      return unless article
      return unless article.respond_to?(:semantic_interests)
      return if article.semantic_interests.present? # Already processed

      # Combine title and body for a rich representation
      text_to_embed = "#{article.title} #{article.description} #{article.tags.pluck(:name).join(' ')}"
      
      # Use full body content for maximum semantic richness. 
      # Gemini's context window can easily handle full articles.
      text_to_embed += " #{article.body_markdown.first(2_500)}" if article.body_markdown.present?

      ai_client = Ai::Base.new
      embedding = ai_client.embed(text_to_embed)

      if embedding
        extractor = Ai::InterestExtractor.new(embedding)
        interests = extractor.extract
        
        article.update_column(:semantic_interests, interests)
      end
    rescue StandardError => e
      Rails.logger.error("Failed to embed article #{article_id}: #{e.message}")
    end
  end
end
