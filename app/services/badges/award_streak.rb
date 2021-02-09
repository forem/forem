module Badges
  class AwardStreak
    LONGEST_STREAK_WEEKS = 16
    LONGEST_STREAK_MESSAGE = "16 weeks! You've achieved the longest writing " \
      "streak possible. This makes you eligible for special quests in the future. " \
      "Keep up the amazing contributions to our community!".freeze

    MINIMUM_QUALITY = -25

    MESSAGE_TEMPLATE =
      "Congrats on achieving this streak! Consistent writing is hard. " \
      "The next streak badge you can get is the %<weeks>d Week Badge. 😉".freeze

    def self.call(weeks:)
      new(weeks: weeks).call
    end

    def initialize(weeks:)
      @weeks = weeks
    end

    def call
      badge_slug = "#{weeks}-week-streak"
      return unless (badge_id = Badge.id_for_slug(badge_slug))

      users = User.where(id: article_user_ids).where("articles_count >= ?", weeks)

      users.find_each do |user|
        count = weeks.times.count { |i| published_x_weeks_ago?(user, i + 1) }
        next unless count >= weeks

        user.badge_achievements.create(
          badge_id: badge_id,
          rewarding_context_message_markdown: generate_message,
        )
      end
    end

    private

    attr_reader :weeks

    # No credit for super low quality
    def article_user_ids
      Article.published
        .where("published_at > ? AND score > ?", 1.week.ago, MINIMUM_QUALITY)
        .pluck(:user_id)
    end

    def published_x_weeks_ago?(user, num)
      user.articles.published
        .where("published_at > ? AND published_at < ?", num.weeks.ago, (num - 1).weeks.ago).any?
    end

    def generate_message
      return LONGEST_STREAK_MESSAGE if weeks == LONGEST_STREAK_WEEKS

      format(MESSAGE_TEMPLATE, weeks: weeks * 2)
    end
  end
end
