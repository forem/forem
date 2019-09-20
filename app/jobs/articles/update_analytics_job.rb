module Articles
  class UpdateAnalyticsJob < ApplicationJob
    queue_as :articles_update_analytics

    def perform(user_id, analytics_updater = Articles::AnalyticsUpdater)
      user = User.find_by(id: user_id)
      return unless user

      analytics_updater.call(user)
    end
  end
end
