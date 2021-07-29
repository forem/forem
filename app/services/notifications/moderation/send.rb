# Send notifications from moderation
module Notifications
  module Moderation
    class Send
      def initialize(moderator, notifiable)
        @moderator = moderator
        @notifiable = notifiable
      end

      def self.call(...)
        new(...).call
      end

      delegate :user_data, :comment_data, to: Notifications

      def call
        # notifiable is currently only comment
        return unless notifiable_supported?(notifiable)

        # do not create the notification if the comment was created by the moderator
        return if moderator == notifiable.user

        json_data = { user: user_data(User.staff_account) }
        json_data[notifiable.class.name.downcase] = public_send "#{notifiable.class.name.downcase}_data", notifiable
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
