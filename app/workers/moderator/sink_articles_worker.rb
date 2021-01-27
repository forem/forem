module Moderator
  class SinkArticlesWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      articles = Article.where(user: user)
      reactions = Reaction.where(reactable: articles)
      new_score = reactions.sum(:points) + Reaction.where(reactable: user).sum(:points)
      articles.update_all(score: new_score)
    rescue StandardError => e
      ForemStatsClient.count("moderators.sink", 1, tags: ["action:failed", "user_id:#{user.id}"])
      Honeybadger.notify(e)
    end
  end
end
