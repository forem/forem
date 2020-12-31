module Badges
  class AwardContributor
    BADGE_SLUG = "dev-contributor".freeze

    def self.call(usernames, message_markdown = "Thank you so much for your contributions!")
      ::Badges::Award.call(
        User.where(username: usernames),
        BADGE_SLUG,
        message_markdown,
      )
    end
  end
end
