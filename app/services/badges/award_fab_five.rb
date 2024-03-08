module Badges
  class AwardFabFive
    BADGE_SLUG = "fab-5".freeze

    def self.call(usernames, message_markdown = default_message_markdown)
      ::Badges::Award.call(
        User.where(username: usernames),
        BADGE_SLUG,
        message_markdown,
      )
    end

    def self.default_message_markdown
      I18n.t("services.badges.congrats", community: Settings::Community.community_name)
    end
  end
end
