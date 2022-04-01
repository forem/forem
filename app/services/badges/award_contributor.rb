module Badges
  class AwardContributor
    BADGE_SLUG = "dev-contributor".freeze

    def self.call(usernames, message_markdown = I18n.t("services.badges.thank_you"))
      ::Badges::Award.call(
        User.where(username: usernames),
        BADGE_SLUG,
        message_markdown,
      )
    end
  end
end
