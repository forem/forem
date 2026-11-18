module Badges
  class Award
    def self.call(user_relation, slug, message_markdown, include_default_description: true)
      badge = Badge.select(:id, :allow_multiple_awards).find_by(slug: slug)
      return unless badge

      relation = user_relation
      unless badge.allow_multiple_awards
        relation = relation.where(
          "NOT EXISTS (SELECT 1 FROM badge_achievements " \
          "WHERE badge_achievements.user_id = users.id AND badge_achievements.badge_id = ?)",
          badge.id,
        )
      end

      relation.find_each do |user|
        next if user.banished?

        achievement = user.badge_achievements.create(
          badge_id: badge.id,
          rewarding_context_message_markdown: message_markdown,
          include_default_description: include_default_description,
        )
        user.touch if achievement.persisted?
      end
    end
  end
end
