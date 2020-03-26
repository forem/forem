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

        send_welcome_notification
        send_authentication_notification
      end

      def send_welcome_notification
        return if received_notification?(welcome_broadcast) || commented_on_welcome_thread? || user.created_at > 3.hours.ago

        Notification.send_welcome_notification(user.id, welcome_broadcast.id)
      end

      def send_authentication_notification
        return if authenticated_with_both_services? || received_notification?(authentication_broadcast) || user.created_at > 1.day.ago

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
        identities.count == 2
      end

      def welcome_broadcast
        @welcome_broadcast ||= Broadcast.find_by(title: "Welcome Notification: welcome_thread")
      end

      def identities
        @identities ||= user.identities.where(provider: %w[github twitter])
      end

      def authentication_broadcast
        missing_identity = identities.exists?(provider: "github") ? "twitter_connect" : "github_connect"
        @authentication_broadcast ||= Broadcast.find_by(title: "Welcome Notification: #{missing_identity}")
      end
    end
  end
end
