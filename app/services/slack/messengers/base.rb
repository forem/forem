module Slack
  module Messengers
    class Base
      def self.call(...)
        new(...).call
      end

      private

      def enqueue_slack_message(message_data)
        return if ENV["DISABLE_SLACK_NOTIFICATIONS"].present?

        Slack::Messengers::Worker.perform_async(message_data)
      end
    end
  end
end
