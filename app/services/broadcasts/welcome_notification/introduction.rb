module Broadcasts
  module WelcomeNotification
    class Introduction
      attr_reader :user

      def initialize(user)
        @user = user
      end

      def self.send(*args)
        new(*args).send
      end

      def send
        return if commented_on_welcome_thread? || received_notification?

        Notification.send_welcome_notification(user.id, welcome_broadcast.id)
      end

      private

      def commented_on_welcome_thread?
        welcome_thread = Article.admin_published_with("welcome").first
        Comment.where(commentable: welcome_thread, user: user).any?
      end

      def received_notification?
        Notification.exists?(notifiable: welcome_broadcast, user: user)
      end

      def welcome_broadcast
        @welcome_broadcast ||= Broadcast.find_by(title: "Welcome Notification: welcome_thread")
      end
    end
  end
end
