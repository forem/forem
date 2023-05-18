# Send notifications from moderation
module Notifications
  module Moderation
    MODERATORS_AVAILABILITY_DELAY = 22.hours
    class Send
      SUPPORTED = [Comment, Article].freeze

      def self.call(...)
        new(...).call
      end

      def initialize(moderator, notifiable)
        @moderator = moderator
        @notifiable = notifiable
      end

      delegate :user_data, :comment_data, :article_data, to: Notifications

      def call
        return unless notifiable_supported?(notifiable)

        # do not create the notification if the comment/article was created by the moderator
        return if moderator == notifiable.user

        json_data = { user: user_data(User.staff_account) }
        notifiable_name = notifiable.class.name.downcase
        json_data[notifiable_name] = public_send "#{notifiable_name}_data", notifiable
        json_data["#{notifiable_name}_user"] = user_data(notifiable.user)
        new_notification = Notification.create!(
          user_id: moderator.id,
          notifiable_id: notifiable.id,
          notifiable_type: notifiable.class.name,
          action: "Moderation",
          json_data: json_data,
        )
        moderator.update_column(:last_moderation_notification, Time.current)
        new_notification
      end

      private

      attr_reader :notifiable, :moderator

      def notifiable_supported?(notifiable)
        SUPPORTED.include?(notifiable.class)
      end
    end
  end
end
