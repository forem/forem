module Slack
  module Messengers
    class Sponsorship
      MESSAGE_TEMPLATE =

        def initialize(user:, organization:, level:, tag: nil)
          @user = user
          @organization = organization
          @level = level
          @tag = tag
        end

      def self.call(...)
        new(...).call
      end

      def call
        type = tag.present? ? "##{tag.name}" : level
        message = I18n.t(
          "services.slack.messengers.sponsorship.user_s_bought_a_type_s_sp",
          user: user.username,
          type: type,
          organization: organization.username,
        )

        Slack::Messengers::Worker.perform_async(
          message: message,
          channel: "incoming-partners",
          username: "media_sponsor",
          icon_emoji: ":partyparrot:",
        )
      end

      private

      attr_reader :user, :organization, :level, :tag
    end
  end
end
