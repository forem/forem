module Moderator
  class BanishUserWorker
    include Sidekiq::Worker

    sidekiq_options queue: :high_priority, retry: 10

    def perform(admin_id, abuser_id)
      abuser = User.find(abuser_id)
      admin = User.find(admin_id)
      Moderator::BanishUser.call(admin: admin, user: abuser)
    rescue StandardError => e
      ForemStatsClient.count("moderators.banishuser", 1, tags: ["action:failed", "user_id:#{abuser.id}"])
      Honeybadger.notify(e)
    end
  end
end
