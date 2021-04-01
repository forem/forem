module Slack
  module Messengers
    class ReactionVomit
      MESSAGE_TEMPLATE = <<~TEXT.chomp.freeze
        %<name>s (%<user_url>s)
        reacted with a vomit on
        %<reactable_url>s
      TEXT

      def initialize(reaction:)
        @reaction = reaction
      end

      def self.call(...)
        new(...).call
      end

      def call
        return unless reaction.category == "vomit"

        user = reaction.user

        message = format(
          MESSAGE_TEMPLATE,
          name: user.name,
          user_url: URL.user(user),
          reactable_url: URL.reaction(reaction),
        )

        Slack::Messengers::Worker.perform_async(
          message: message,
          channel: "abuse-reports",
          username: "abuse_bot",
          icon_emoji: ":cry:",
        )
      end

      private

      attr_reader :reaction
    end
  end
end
