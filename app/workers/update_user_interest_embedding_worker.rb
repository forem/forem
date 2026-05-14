class UpdateUserInterestEmbeddingWorker
  include Sidekiq::Job
  sidekiq_options queue: :low_priority, lock: :until_executing, on_conflict: :replace

  # Blend factor determines how fast the user's interests shift. 0.2 means 20% weight to new article, 80% to old interests.
  BLEND_FACTOR = 0.2

  def perform(user_id, article_id)
    article = Article.find_by(id: article_id)
    return unless article && article.respond_to?(:semantic_embedding) && article.semantic_embedding.present?

    article_vector = article.semantic_embedding.to_a
    return unless article_vector.length == 768

    UserActivity.transaction do
      user_activity = UserActivity.lock.find_or_create_by!(user_id: user_id)

      if user_activity.respond_to?(:interest_embedding)
        current_vector = user_activity.interest_embedding&.to_a

        new_vector = if current_vector.blank? || current_vector.length != 768
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
  end
end
