# Creates and sends a specific welcome notification.
module Notifications
  module WelcomeNotification
    class Send
      def initialize(receiver_id, welcome_broadcast)
        @receiver_id = receiver_id
        @welcome_broadcast = welcome_broadcast
      end

      delegate :user_data, to: Notifications

      def self.call(*args)
        new(*args).call
      end

      def call
        mascot_account = User.mascot_account
        json_data = {
          user: user_data(mascot_account),
          broadcast: {
            title: welcome_broadcast.title,
            processed_html: welcome_broadcast.processed_html
          }
        }
        Notification.create!(
          user_id: receiver_id,
          notifiable_id: welcome_broadcast.id,
          notifiable_type: "Broadcast",
          action: welcome_broadcast.type_of,
          json_data: json_data,
        )
      end

      private

      attr_reader :receiver_id, :welcome_broadcast
    end
  end
end
