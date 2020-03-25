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
        return unless user

        send_welcome_notification
        send_authentication_notification
      end

      def send_welcome_notification
        return if received_notification?(welcome_broadcast) || commented_on_welcome_thread?

        Notification.send_welcome_notification(user.id, welcome_broadcast.id)
      end

      def send_authentication_notification
        return if received_notification?(authentication_broadcast) || authenticated_with_both_services? || user.created_at > 1.day.ago

        Notification.send_welcome_notification(user.id, authentication_broadcast.id)
      end

      private

      attr_reader :user

      def received_notification?(broadcast)
        Notification.exists?(notifiable: broadcast, user: user)
      end

      def commented_on_welcome_thread?
        welcome_thread = Article.admin_published_with("welcome").first
        Comment.where(commentable: welcome_thread, user: user).any?
      end

      def authenticated_with_both_services?
        user.identities.exists?(provider: "github") && user.identities.exists?(provider: "twitter")
      end

      def welcome_broadcast
        @welcome_broadcast ||= Broadcast.find_by(title: "Welcome Notification: welcome_thread")
      end

      def authentication_broadcast
        missing_identity = user.identities.exists?(provider: "github") ? "twitter_connect" : "github_connect"
        @authentication_broadcast ||= Broadcast.find_by(title: "Welcome Notification: #{missing_identity}")
      end
    end
  end
end
