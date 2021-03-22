module Slack
  module Messengers
    class PotentialSpammer
      MESSAGE_TEMPLATE = <<~TEXT.chomp.freeze
        Potential spam user! %<url>s
      TEXT

      def initialize(user:)
        @user = user
      end

      def self.call(...)
        new(...).call
      end

      def call
        message = format(
          MESSAGE_TEMPLATE,
          url: URL.user(user),
        )

        Slack::Messengers::Worker.perform_async(
          message: message,
          channel: "potential-spam",
          username: "spam_account_checker_bot",
          icon_emoji: ":exclamation:",
        )
      end

      private

      attr_reader :user
    end
  end
end
