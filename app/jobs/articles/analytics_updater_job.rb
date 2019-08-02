module Articles
  class AnalyticsUpdaterJob < ApplicationJob
    queue_as :article_analytics_updater_job

    def perform(user_id, analytics_updater = Articles::AnalyticsUpdater)
      return unless User.find_by(id: user_id)

      analytics_updater.call(user_id)
    end
  end
end
