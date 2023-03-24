module Slack
  module Messengers
    class PotentialSpammer
      def self.call(...)
        new(...).call
      end

      def initialize(user:)
        @user = user
      end

      def call
        message = I18n.t(
          "services.slack.messengers.potential_spammer.body",
          url: URL.user(user),
        )

        Slack::Messengers::Worker.perform_async(
          "message" => message,
          "channel" => "potential-spam",
          "username" => "spam_account_checker_bot",
          "icon_emoji" => ":exclamation:",
        )
      end

      private

      attr_reader :user
    end
  end
end
