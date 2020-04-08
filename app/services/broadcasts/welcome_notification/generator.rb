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
        return unless user.subscribed_to_welcome_notifications?

        send_welcome_notification unless notification_enqueued
        send_authentication_notification unless notification_enqueued
        send_feed_customization_notification unless notification_enqueued
        send_ux_customization_notification unless notification_enqueued
        send_discuss_and_ask_notification unless notification_enqueued
      rescue ActiveRecord::RecordNotFound => e
        Honeybadger.notify(e)
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

      def send_feed_customization_notification
        return if user_is_following_tags? || received_notification?(customize_feed_broadcast) || user.created_at > 3.days.ago

        Notification.send_welcome_notification(user.id, customize_feed_broadcast.id)
      end

      def send_ux_customization_notification
        return if received_notification?(customize_ux_broadcast) || user.created_at > 5.days.ago

        Notification.send_welcome_notification(user.id, customize_ux_broadcast.id)
        @notification_enqueued = true
      end

      def send_discuss_and_ask_notification
        return if (asked_a_question && started_a_discussion) || received_notification?(discuss_and_ask_broadcast) || user.created_at > 6.days.ago

        Notification.send_welcome_notification(user.id, discuss_and_ask_broadcast.id)
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

      def user_is_following_tags?
        user.cached_followed_tag_names.count > 1
      end

      def welcome_broadcast
        @welcome_broadcast ||= Broadcast.active.find_by!(title: "Welcome Notification: welcome_thread")
      end

      def customize_ux_broadcast
        @customize_ux_broadcast ||= Broadcast.active.find_by!(title: "Welcome Notification: customize_experience")
      end

      def customize_feed_broadcast
        @customize_feed_broadcast ||= Broadcast.active.find_by!(title: "Welcome Notification: customize_feed")
      end

      def authentication_broadcast
        @authentication_broadcast ||= find_auth_broadcast
      end

      def discuss_and_ask_broadcast
        @discuss_and_ask_broadcast ||= find_discuss_ask_broadcast
      end

      def identities
        @identities ||= user.identities.where(provider: SiteConfig.authentication_providers)
      end

      def find_auth_broadcast
        missing_identities = SiteConfig.authentication_providers.map do |provider|
          identities.exists?(provider: provider) ? nil : "#{provider}_connect"
        end.compact
        Broadcast.active.find_by!(title: "Welcome Notification: #{missing_identities.first}")
      end

      def find_discuss_ask_broadcast
        type = if !asked_a_question && started_a_discussion
                 "ask_question"
               elsif !started_a_discussion && asked_a_question
                 "start_discussion"
               else
                 "discuss_and_ask"
               end
        Broadcast.active.find_by!(title: "Welcome Notification: #{type}")
      end

      def asked_a_question
        @asked_a_question ||= Article.user_published_with(user.id, "explainlikeimfive").any?
      end

      def started_a_discussion
        @started_a_discussion ||= Article.user_published_with(user.id, "discuss").any?
      end
    end
  end
end
