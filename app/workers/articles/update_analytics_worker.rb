module Articles
  class UpdateAnalyticsWorker
    include Sidekiq::Worker

    sidekiq_options queue: :low_priority, retry: 15, lock: :until_executing

    def perform(user_id)
      user = User.find_by(id: user_id)
      return unless user

      Articles::AnalyticsUpdater.call(user)
    end
  end
end
