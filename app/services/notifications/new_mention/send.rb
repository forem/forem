module Notifications
  module NewMention
    class Send
      delegate :user_data, to: Notifications
      delegate :comment_data, to: Notifications

      def initialize(mention)
        @mention = mention
      end

      def self.call(...)
        new(...).call
      end

      def call
        Notification.create(
          user_id: mention.user_id,
          notifiable_id: mention.id,
          notifiable_type: "Mention",
          action: nil,
          json_data: json_data,
        )
      end

      private

      attr_reader :mention

      def json_data
        data = { user: user_data(mention.mentionable.user) }
        data[:comment] = comment_data(mention.mentionable) if mention.mentionable_type == "Comment"
        data
      end
    end
  end
end
