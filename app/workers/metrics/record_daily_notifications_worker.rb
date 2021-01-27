module Metrics
  class RecordDailyNotificationsWorker
    include Sidekiq::Worker
    sidekiq_options queue: :low_priority, retry: 10

    EVENT_TITLES = %w[
      welcome_notification_set_up_profile
      welcome_notification_welcome_thread
      welcome_notification_customize_feed
      welcome_notification_twitter_connect
      welcome_notification_github_connect
      welcome_notification_customize_experience
      welcome_notification_discuss_and_ask
      welcome_notification_download_app
      welcome_notification_ask_question
      welcome_notification_start_discussion
    ].freeze

    def perform
      # Welcome Notification click events created in the past day, logged by title.
      EVENT_TITLES.each do |title|
        event = Ahoy::Event.where(name: "Clicked Welcome Notification")
          .where("time > ?", 1.day.ago)
          .where("properties->>'title' = ?", title)

        ForemStatsClient.count(
          "ahoy_events",
          event.size,
          tags: ["title:#{title}"],
        )
      end
    end
  end
end
