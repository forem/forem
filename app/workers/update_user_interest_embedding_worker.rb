class UpdateUserInterestEmbeddingWorker
  include Sidekiq::Job
  sidekiq_options queue: :low, lock: :until_executing, on_conflict: :replace

  # Blend factor determines how fast the user's interests shift. 0.2 means 20% weight to new article, 80% to old interests.
  BLEND_FACTOR = 0.2

  def perform(user_id, article_id)
    user_activity = UserActivity.find_by(user_id: user_id)
    return unless user_activity

    article = Article.find_by(id: article_id)
    return unless article && article.semantic_embedding.present?

    article_vector = article.semantic_embedding.to_a
    current_vector = user_activity.interest_embedding&.to_a

    new_vector = if current_vector.blank?
                   article_vector
                 else
                   # Blend vectors using Exponential Moving Average
                   current_vector.zip(article_vector).map do |c, a|
                     (c * (1 - BLEND_FACTOR)) + (a * BLEND_FACTOR)
                   end
                 end

    user_activity.update_column(:interest_embedding, new_vector)
  end
end
