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
        return if commented_on_welcome_thread? || received_notification?

        welcome_broadcast = Broadcast.find_by(title: "Welcome Notification: welcome_thread")
        Notification.send_welcome_notification(receiver_id, welcome_broadcast.id)
      end

      def received_notification?
        welcome_broadcast = Broadcast.find_by(title: "Welcome Notification: welcome_thread")
        # Find a Notification by its Broadcast, e.g. Notification.notifiable
        # Check whether a Notification exists where a Broadcast is the Broadcast
        # Notification where Notifiable is welcome_broadcast and User is the receiver_id - this must return true
        # notification = Notification.find_by(notifiable_id: welcome_broadcast.id, user_id: receiver_id)
        Notification.find_by(notifiable_id: welcome_broadcast.id, user_id: receiver_id)
      # rescue ActiveRecord::RecordInvalid # attempt to rescue error - this may need to be changed a bit
      #   # raise StandardError, "Invalid User: User is already associated with this notification."
      #   raise "Invalid User: User is already associated with this notification.", if notification.true?
      #                                                                             end
      # rescue StandardError => e
      rescue ActiveRecord::RecordInvalid
        # raise StandardError.new("User is already associated with this notification: #{e}")
        raise StandardError, "User is already associated with this notification."
      end

      def commented_on_welcome_thread?
        welcome_threads = Article.where("slug LIKE 'welcome-thread%'")
        user = User.find_by(id: receiver_id)
        Comment.where(commentable: welcome_threads, user_id: receiver_id).any? && user.created_at + 3.hours <= Time.zone.now
      end

      private

      attr_reader :receiver_id
    end
  end
end
