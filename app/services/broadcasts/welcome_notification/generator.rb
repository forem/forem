module Broadcasts
  module WelcomeNotification
    class Generator
      def initialize(receiver_id)
        @user = User.find(receiver_id)
        @notification_enqueued = false
      end

      def self.call(*args)
        new(*args).call
      end

      def call
        # TODO: [@thepracticaldev/delightful] Move this check into the rake task logic once it has been implemented.
        return unless user.welcome_notifications

        send_welcome_notification unless notification_enqueued
        send_authentication_notification unless notification_enqueued
      end

      private

      attr_reader :user, :notification_enqueued

      def send_welcome_notification
        return if received_notification?(welcome_broadcast) || commented_on_welcome_thread? || user.created_at > 3.hours.ago

        Notification.send_welcome_notification(user.id, welcome_broadcast.id)
        @notification_enqueued = true
      end

      def send_authentication_notification
        return if authenticated_with_all_providers? || received_notification?(authentication_broadcast) || user.created_at > 1.day.ago

        Notification.send_welcome_notification(user.id, authentication_broadcast.id)
        @notification_enqueued = true
      end

      def received_notification?(broadcast)
        Notification.exists?(notifiable: broadcast, user: user)
      end

      def commented_on_welcome_thread?
        welcome_thread = Article.admin_published_with("welcome").first
        Comment.where(commentable: welcome_thread, user: user).any?
      end

      def authenticated_with_all_providers?
        identities.count == SiteConfig.authentication_providers.count
      end

      def welcome_broadcast
        @welcome_broadcast ||= Broadcast.find_by(title: "Welcome Notification: welcome_thread")
      end

      def identities
        @identities ||= user.identities.where(provider: SiteConfig.authentication_providers)
      end

      def authentication_broadcast
        @authentication_broadcast ||= find_broadcast
      end

      def find_broadcast
        missing_identities = SiteConfig.authentication_providers.map do |provider|
          identities.exists?(provider: provider) ? nil : "#{provider}_connect"
        end.compact
        Broadcast.find_by(title: "Welcome Notification: #{missing_identities.first}")
      end
    end
  end
end
