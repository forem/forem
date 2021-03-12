module Moderator
  class SinkArticlesWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      articles = Article.where(user: user)
      reactions = Reaction.where(reactable: user)
      articles.each do |article|
        article.update(score: article.score + reactions.sum(&:points))
      end
    rescue StandardError => e
      ForemStatsClient.count("moderators.sink", 1, tags: ["action:failed", "user_id:#{user.id}"])
      Honeybadger.notify(e)
    end
  end
end
