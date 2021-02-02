module Badges
  class Award
    def self.call(user_relation, slug, message_markdown)
      return unless (badge_id = Badge.id_for_slug(slug))

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
