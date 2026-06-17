module Events
  class SendNotificationsWorker
    include Sidekiq::Job
    sidekiq_options queue: :default, retry: 3, lock: :until_executing, on_conflict: :replace

    def perform
      # Send 1-day-before notifications
      signups_1_day = EventSignup.joins(:event)
                                 .where(notified_1_day_before: false)
                                 .where("events.start_time <= ?", Time.current + 24.hours)
                                 .where("events.start_time > ?", Time.current + 1.hour)

      signups_1_day.find_each do |signup|
        ActiveRecord::Base.transaction do
          Notifications::EventNotification::Send.call(signup, "1 day")
          signup.update!(notified_1_day_before: true)
        end
      end

      # Send 1-hour-before notifications
      signups_1_hour = EventSignup.joins(:event)
                                  .where(notified_1_hour_before: false)
                                  .where("events.start_time <= ?", Time.current + 1.hour)
                                  .where("events.start_time > ?", Time.current)

      signups_1_hour.find_each do |signup|
        ActiveRecord::Base.transaction do
          Notifications::EventNotification::Send.call(signup, "1 hour")
          signup.update!(notified_1_hour_before: true)
        end
      end
    end
  end
end
