module Badges
  class AwardTopSeven
    BADGE_SLUG = "top-7".freeze

    def self.call(usernames, message_markdown = default_message_markdown)
      users = User.where(username: usernames)
      
      # The reputation modifier changes are now handled automatically 
      # via the BadgeAchievement callback when badges are awarded
      ::Badges::Award.call(
        users,
        BADGE_SLUG,
        message_markdown,
      )
    end

    def self.default_message_markdown
      I18n.t("services.badges.congrats", community: Settings::Community.community_name)
    end
  end
end
