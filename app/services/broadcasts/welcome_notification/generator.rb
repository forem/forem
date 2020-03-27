# Generates a broadcast to be delivered as a notification.
module Broadcasts
  module WelcomeNotification
    class Generator
      def initialize(receiver_id)
        @user = User.find(receiver_id)
      end

      def self.call(*args)
        new(*args).call
      end

      def call
        # TODO: [@thepracticaldev/delightful] Move this check into the rake task logic once it has been implemented.
        return unless user.welcome_notifications
        return if commented_on_welcome_thread? || received_notification?

        Notification.send_welcome_notification(user.id, welcome_broadcast.id)
      end

      def received_notification?
        Notification.exists?(notifiable: welcome_broadcast, user: user)
      end

      def commented_on_welcome_thread?
        welcome_thread = Article.admin_published_with("welcome").first
        Comment.where(commentable: welcome_thread, user: user).any?
      end

      private

      def welcome_broadcast
        @welcome_broadcast ||= Broadcast.find_by(title: "Welcome Notification: welcome_thread")
      end

      attr_reader :user
    end
  end
end
