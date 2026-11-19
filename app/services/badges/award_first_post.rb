module Badges
  class AwardFirstPost
    BADGE_SLUG = "writing-debut".freeze

    def self.call
      badge = Badge.select(:id, :allow_multiple_awards).find_by(slug: BADGE_SLUG)
      return unless badge

      scope = Article.joins(:user)
        .published
        .where("articles.published_at > ?", 1.week.ago)
        .where("articles.published_at < ?", 1.hour.ago)
        .where("articles.score >= ?", 0)
        .where(nth_published_by_author: 1)
        .where.not(users: { id: User.with_role(:spam).or(User.with_role(:suspended)) })

      unless badge.allow_multiple_awards
        scope = scope.where(
          "NOT EXISTS (SELECT 1 FROM badge_achievements " \
          "WHERE badge_achievements.user_id = articles.user_id AND badge_achievements.badge_id = ?)",
          badge.id,
        )
      end

      scope.find_each do |article|
        BadgeAchievement.create(
          user_id: article.user_id,
          badge_id: badge.id,
        )
      end
    end
  end
end
