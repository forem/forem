module Broadcasts
  class SendWelcomeNotificationsWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 15

    def perform
      # In order to prevent new users from receiving multiple welcome notifications in a day,
      # a feature_live_date is required. The script will only be effective after feature_live_date
      # and will ultimately be superseded by 7.days.ago when it's larger than feature_live_date.
      return unless Settings::General.welcome_notifications_live_at

      User.select(:id).where("created_at > ?", created_after).find_each do |user|
        Broadcasts::WelcomeNotification::Generator.call(user.id)
      end
    end

    def created_after
      [Settings::General.welcome_notifications_live_at, 7.days.ago].max
    end
    private :created_after
  end
end
