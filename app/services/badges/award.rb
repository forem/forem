module Badges
  class Award
    def self.call(user_relation, slug, message_markdown, include_default_description: true)
      return unless (badge_id = Badge.id_for_slug(slug))

      user_relation.find_each do |user|
        next if user.banished?

        achievement = user.badge_achievements.create(
          badge_id: badge_id,
          rewarding_context_message_markdown: message_markdown,
          include_default_description: include_default_description,
        )
        user.touch if achievement.persisted?
      end
    end
  end
end
