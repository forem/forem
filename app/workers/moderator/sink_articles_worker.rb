module Moderator
  class SinkArticlesWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 10

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      Article.where(user: user).each(&:update_score)
    rescue StandardError => e
      ForemStatsClient.count("moderators.sink", 1, tags: ["action:failed", "user_id:#{user.id}"])
      Honeybadger.notify(e)
    end
  end
end
