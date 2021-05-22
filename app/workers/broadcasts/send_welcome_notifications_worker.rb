module Broadcasts
  class SendWelcomeNotificationsWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 15

    def perform
      # In order to prevent new users from receiving multiple welcome notifications in a day,
      # a feature_live_date is required. The script will only be effective after feature_live_date
      # and will ultimately be superseded by 7.days.ago when it's larger than feature_live_date.
      return unless Settings::General.welcome_notifications_live_at

      notifications_live_at = Settings::General.welcome_notifications_live_at
      week_ago = 7.days.ago
      latest_date = notifications_live_at > week_ago ? notifications_live_at : week_ago
      User.select(:id).where("created_at > ?", latest_date).find_each do |user|
        Broadcasts::WelcomeNotification::Generator.call(user.id)
      end
    end
  end
end
