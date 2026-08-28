module Badges
  class AwardCommunityFavorite
    BADGE_SLUG = "community-favorite".freeze

    def self.call(...)
      new(...).call
    end

    def initialize(favoritable:, favoriter:)
      @favoritable = favoritable
      @favoriter = favoriter
    end

    def call
      return unless (badge_id = Badge.id_for_slug(BADGE_SLUG))
      return if favoritable.user_id.blank?

      achievement = BadgeAchievement.create(
        user_id: favoritable.user_id,
        badge_id: badge_id,
        rewarder_id: favoriter.id,
        rewarding_context_message_markdown: message,
      )
      favoritable.user.touch if achievement.valid?

      achievement
    end

    private

    attr_reader :favoritable, :favoriter

    def message
      key = comment? ? "comment_message" : "article_message"
      I18n.t("services.badges.award_community_favorite.#{key}", url: favoritable_url)
    end

    def favoritable_url
      comment? ? URL.comment(favoritable) : URL.article(favoritable)
    end

    def comment?
      favoritable.is_a?(Comment)
    end
  end
end
