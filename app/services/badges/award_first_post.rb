module Badges
  class AwardFirstPost
    BADGE_SLUG = "writing-debut".freeze

    def self.call
      return unless (badge_id = Badge.id_for_slug(BADGE_SLUG))

      Article.joins(:user)
        .published
        .where("articles.published_at > ?", 1.week.ago)
        .where("articles.published_at < ?", 1.hour.ago)
        .where("articles.score >= ?", 0)
        .where(nth_published_by_author: 1)
        .where.not(users: { id: User.with_role(:spam).or(User.with_role(:suspended)) })
        .find_each do |article|
          BadgeAchievement.create(
            user_id: article.user_id,
            badge_id: badge_id,
          )
        end
    end
  end
end
