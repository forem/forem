module Broadcasts
  module WelcomeNotification
    class Generator
      def self.call(...)
        new(...).call
      end

      def initialize(receiver_id)
        @user = User.find(receiver_id)
        @notification_enqueued = false
      end

      def call
        return unless user.notification_setting.subscribed_to_welcome_notifications?

        notification_methods.each do |method|
          send method unless notification_enqueued # rubocop:disable Style/Send
        rescue ActiveRecord::RecordNotFound => e
          Honeybadger.notify(e)
        end
      end

      private

      attr_reader :user, :notification_enqueued

      def notification_methods
        %i[
          send_welcome_notification
          send_authentication_notification
          send_feed_customization_notification
          send_ux_customization_notification
          send_discuss_and_ask_notification
          send_download_app_notification
        ]
      end

      def send_welcome_notification
        return if
          user.created_at.after?(3.hours.ago) ||
            received_notification?(welcome_broadcast) ||
            commented_on_welcome_thread?

        Notification.send_welcome_notification(user.id, welcome_broadcast.id)
        # Setting @notification_enqueued here prevents us from sending a user two welcome notifications in one day.
        @notification_enqueued = true
      end

      def send_authentication_notification
        return if
          user.created_at.after?(1.day.ago) ||
            authenticated_with_all_providers? ||
            received_notification?(authentication_broadcasts)

        Notification.send_welcome_notification(user.id, authentication_broadcast.id)
        @notification_enqueued = true
      end

      def send_feed_customization_notification
        return if
          user.created_at.after?(3.days.ago) ||
            user_following_tags? ||
            received_notification?(customize_feed_broadcast)

        Notification.send_welcome_notification(user.id, customize_feed_broadcast.id)
        @notification_enqueued = true
      end

      def send_ux_customization_notification
        return if user.created_at.after?(5.days.ago) || received_notification?(customize_ux_broadcast)

        Notification.send_welcome_notification(user.id, customize_ux_broadcast.id)
        @notification_enqueued = true
      end

      def send_discuss_and_ask_notification
        return if
          user.created_at.after?(6.days.ago) ||
            (asked_a_question && started_a_discussion) ||
            received_notification?(discuss_and_ask_broadcast)

        Notification.send_welcome_notification(user.id, discuss_and_ask_broadcast.id)
        @notification_enqueued = true
      end

      def send_download_app_notification
        return if user.created_at.after?(7.days.ago) || received_notification?(download_app_broadcast)

        Notification.send_welcome_notification(user.id, download_app_broadcast.id)
        @notification_enqueued = true
      end

      def received_notification?(broadcast)
        Notification.exists?(notifiable: broadcast, user: user)
      end

      def commented_on_welcome_thread?
        welcome_thread = Article.admin_published_with("welcome").first
        Comment.where(commentable: welcome_thread, user: user).any?
      end

      def authentication_broadcasts
        Broadcast.active.where(type_of: "Welcome").where("title like '%_connect'")
      end

      def providers
        # we filter the providers to suggest based on the following two criteria
        # - provider is enabled
        # - an acive provider Broadcast message exists
        # Disabling/deactivating a provider_connect broadcast removes
        # the provider from suggestions sent to users
        @providers ||=
          Authentication::Providers.enabled.select do |provider|
            authentication_broadcasts.exists?(title: I18n.t(
              "services.broadcasts.welcome_notification.generator.welcome", key: "#{provider}_connect"
            ))
          end
      end

      def authenticated_with_all_providers?
        providers.all? { |sym| identities.exists?(provider: sym) }
      end

      def user_following_tags?
        user.cached_followed_tag_names.count > 1
      end

      def welcome_broadcast
        @welcome_broadcast ||= Broadcast.active.find_by!(title: I18n.t(
          "services.broadcasts.welcome_notification.generator.welcome", key: "welcome_thread"
        ))
      end

      def customize_ux_broadcast
        @customize_ux_broadcast ||= Broadcast.active.find_by!(title: I18n.t(
          "services.broadcasts.welcome_notification.generator.welcome", key: "customize_experience"
        ))
      end

      def customize_feed_broadcast
        @customize_feed_broadcast ||= Broadcast.active.find_by!(title: I18n.t(
          "services.broadcasts.welcome_notification.generator.welcome", key: "customize_feed"
        ))
      end

      def authentication_broadcast
        @authentication_broadcast ||= find_auth_broadcast
      end

      def discuss_and_ask_broadcast
        @discuss_and_ask_broadcast ||= find_discuss_ask_broadcast
      end

      def download_app_broadcast
        @download_app_broadcast ||= Broadcast.active.find_by!(title: I18n.t(
          "services.broadcasts.welcome_notification.generator.welcome", key: "download_app"
        ))
      end

      def identities
        @identities ||= user.identities.enabled
      end

      def find_auth_broadcast
        missing_identities = providers.filter_map do |provider|
          identities.exists?(provider: provider) ? nil : "#{provider}_connect"
        end

        Broadcast.active.find_by!(title: I18n.t("services.broadcasts.welcome_notification.generator.welcome",
                                                key: missing_identities.first))
      end

      def find_discuss_ask_broadcast
        type = if !asked_a_question && started_a_discussion
                 "ask_question"
               elsif !started_a_discussion && asked_a_question
                 "start_discussion"
               else
                 "discuss_and_ask"
               end
        Broadcast.active.find_by!(title: I18n.t("services.broadcasts.welcome_notification.generator.welcome",
                                                key: type))
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
