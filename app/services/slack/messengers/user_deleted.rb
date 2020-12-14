module Slack
  module Messengers
    class UserDeleted
      MESSAGE_TEMPLATE = <<~TEXT.chomp.freeze
        %<name>s (%<user_url>s)
        self-deleted their account.
        Please, delete them from Mailchimp & Google Analytics.
      TEXT

      def initialize(name:, user_url:)
        @name = name
        @user_url = user_url
      end

      def self.call(*args)
        new(*args).call
      end

      def call
        message = format(
          MESSAGE_TEMPLATE,
          name: name,
          user_url: user_url,
        )

        Slack::Messengers::Worker.perform_async(
          message: message,
          channel: "user-deleted",
          username: "user_deleted_bot",
          icon_emoji: ":scissors:",
        )
      end

      private

      attr_reader :name, :user_url
    end
  end
end
