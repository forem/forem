module Broadcasts
  class SendWelcomeNotificationsWorker
    include Sidekiq::Worker

    sidekiq_options queue: :medium_priority, retry: 15

    def perform
      return unless Settings::General.welcome_notifications_live_at

      User.select(:id).where("created_at > ?", created_after).find_each do |user|
        # the Generator ensures only one notification is created per user per day
        Broadcasts::WelcomeNotification::Generator.call(user.id)
      end
    end

    def created_after
      # The script will only be effective after feature_live_date
      # and will ultimately be superseded by 8.days.ago when it's larger than feature_live_date.
      [Settings::General.welcome_notifications_live_at, 8.days.ago].max
    end
    private :created_after
  end
end
