module RatingVotes
  class AssignRatingWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 10, lock: :until_executing

    def perform(article_id, group = "experience_level")
      article = Article.find_by(id: article_id)
      return unless article

      ratings = article.rating_votes.where(group: group).pluck(:rating)
      average = ratings.sum / ratings.size

      article.update_columns(
        experience_level_rating: average,
        experience_level_rating_distribution: ratings.max - ratings.min,
        last_experience_level_rating_at: Time.current,
      )
      article.index_to_elasticsearch_inline
    end
  end
end
