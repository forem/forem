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
        # welcome_broadcast = # Rubocop will NOT leave me alone and keeps throwing errors in this entire method, so this will have to stay like this for now
        return if has_commented_on_welcome_thread?

        welcome_broadcast = Broadcast.find_by(title: "Welcome Notification")
        # Find the correct, welcome_thread in this case, Broadcast
        Notification.send_welcome_notification(receiver_id, welcome_broadcast.id)
        # Send the welcome_notification once the appropriate Broadcast has been found
      end

      def has_commented_on_welcome_thread?
        welcome_threads = Article.where("slug LIKE 'welcome-thread%'")
        # Find all Articles containing the Welcome Thread slug
        Comment.where(commentable: welcome_threads, user_id: receiver_id).any?
        # Check to see if there are any comments on the Welcome Thread Articles by the User
      end

      private

      attr_reader :receiver_id
    end
  end
end
