module Badges
  class AwardTopSeven
    BADGE_SLUG = "top-7".freeze

    def self.call(usernames, message_markdown = I18n.t("services.badges.congrats"))
      ::Badges::Award.call(
        User.where(username: usernames),
        BADGE_SLUG,
        message_markdown,
      )
    end
  end
end
