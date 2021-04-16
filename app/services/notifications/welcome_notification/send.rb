# Creates and sends a specific welcome notification.
module Notifications
  module WelcomeNotification
    class Send
      def initialize(receiver_id, welcome_broadcast)
        @receiver_id = receiver_id
        @welcome_broadcast = welcome_broadcast
      end

      delegate :user_data, to: Notifications

      def self.call(...)
        new(...).call
      end

      def call
        mascot_account = User.mascot_account
        json_data = {
          user: user_data(mascot_account),
          broadcast: {
            title: welcome_broadcast.title,
            processed_html: welcome_broadcast.processed_html,
            type_of: welcome_broadcast.type_of
          }
        }
        Notification.create!(
          user_id: receiver_id,
          notifiable_id: welcome_broadcast.id,
          notifiable_type: "Broadcast",
          action: welcome_broadcast.type_of,
          json_data: json_data,
        )

        log_to_datadog
      end

      private

      attr_reader :receiver_id, :welcome_broadcast

      def log_to_datadog
        ForemStatsClient.increment(
          "notifications.welcome",
          tags: ["user_id:#{receiver_id}", "title:#{welcome_broadcast.title}"],
        )
      end
    end
  end
end
