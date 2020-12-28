module Badges
  class AwardFabFive
    BADGE_SLUG = "fab-5".freeze
    DEFAULT_MESSAGE = "Congrats!!!".freeze

    def self.call(usernames, message_markdown = DEFAULT_MESSAGE)
      ::Badges::Award.call(
        User.where(username: usernames),
        BADGE_SLUG,
        message_markdown,
      )
    end
  end
end
