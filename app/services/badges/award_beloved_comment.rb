module Badges
  class AwardBelovedComment
    BADGE_SLUG = "beloved-comment".freeze
    BATCH_SIZE = 200

    def self.call(comment_count = 25)
      new(comment_count).call
    end

    def initialize(comment_count)
      @comment_count = comment_count
    end

    def call
      badge = Badge.select(:id, :allow_multiple_awards).find_by(slug: BADGE_SLUG)
      return unless badge

      awarded_user_ids = Set.new

      qualifying_comments(badge).includes(:user, :commentable).find_each(batch_size: BATCH_SIZE) do |comment|
        next unless comment.user
        next if !badge.allow_multiple_awards && awarded_user_ids.include?(comment.user_id)

        achievement = BadgeAchievement.create(
          user_id: comment.user_id,
          badge_id: badge.id,
          rewarding_context_message_markdown: generate_message(comment),
        )
        next unless achievement.persisted?

        awarded_user_ids << comment.user_id unless badge.allow_multiple_awards
        comment.user.touch
      end
    end

    private

    attr_reader :comment_count

    def qualifying_comments(badge)
      scope = Comment.where(public_reactions_count: comment_count..)
      return scope if badge.allow_multiple_awards

      scope.where(
        "NOT EXISTS (SELECT 1 FROM badge_achievements " \
        "WHERE badge_achievements.user_id = comments.user_id AND badge_achievements.badge_id = ?)",
        badge.id,
      )
    end

    def generate_message(comment)
      I18n.t("services.badges.award_beloved_comment.message", comment: URL.comment(comment))
    end
  end
end
