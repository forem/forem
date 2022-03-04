module Badges
  class AwardFabFive
    BADGE_SLUG = "fab-5".freeze

    def self.call(usernames, message_markdown = I18n.t("services.badges.congrats"))
      ::Badges::Award.call(
        User.where(username: usernames),
        BADGE_SLUG,
        message_markdown,
      )
    end
  end
end
