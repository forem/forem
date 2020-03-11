# Generates a broadcast to be delivered as a notification.
module Broadcasts
  module WelcomeNotification
    class Generator
      def initialize(receiver_id)
        @receiver_id = receiver_id
      end

      def self.call(*args)
        new(*args).call
      end

      def call
        # This method should find the user based on the `receiver_id`.
        # It should then determine the appropriate Broadcast for a user,
        # based on the `created_at` and the different conditions for sending a notification.
        # `welcome_broadcast = ...`

        # Once it has the appropriate Broadcast to be sent, it should send a notification for it:
        # `Notification.send_welcome_notification(receiver_id, welcome_broadcast.id)`
      end

      private

      attr_reader :receiver_id
    end
  end
end
