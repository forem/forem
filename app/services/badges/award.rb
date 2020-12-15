module Badges
  class Award
    def self.call(user_relation, slug, message_markdown)
      badge_id = Badge.find_by(slug: slug)&.id
      return unless badge_id

      user_relation.find_each do |user|
        achievement = user.badge_achievements.create(
          badge_id: badge_id,
          rewarding_context_message_markdown: message_markdown,
        )
        user.touch if achievement.persisted?
      end
    end
  end
end
