module Badges
  class AwardTag
    def self.call
      new.call
    end

    def call
      Tag.where.not(badge_id: nil).find_each do |tag|
        past_winner_user_ids = BadgeAchievement.where(badge_id: tag.badge_id).pluck(:user_id)
        winning_article = Article.where("score > 100")
          .published
          .where.not(user_id: past_winner_user_ids)
          .order(score: :desc)
          .where("published_at > ?", 7.5.days.ago) # More than seven days, to have some wiggle room.
          .cached_tagged_with(tag).first
        next unless winning_article

        user = winning_article.user
        achievement = user.badge_achievements.create(
          badge_id: tag.badge_id,
          rewarding_context_message_markdown: generate_message(tag, winning_article),
        )
        user.touch if achievement.persisted?
      end
    end

    private

    def generate_message(tag, winning_article)
      "Congratulations on posting the most beloved [##{tag.name}](#{URL.tag(tag)}) post " \
        "from the past seven days! " \
        "Your winning post was [#{winning_article.title}](#{URL.article(winning_article)}). " \
        "(You can only win once per badge-eligible tag)"
    end
  end
end
