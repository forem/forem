module Badges
  class AwardStreak
    LONGEST_STREAK_WEEKS = 16
    MINIMUM_QUALITY = -25
    BATCH_SIZE = 500

    def self.call(weeks:)
      new(weeks: weeks).call
    end

    def initialize(weeks:)
      @weeks = weeks
    end

    def call
      badge = Badge.select(:id, :allow_multiple_awards).find_by(slug: "#{weeks}-week-streak")
      return unless badge

      reference_time = Time.current
      message = generate_message

      candidate_user_ids(badge, reference_time).each_slice(BATCH_SIZE) do |batch_user_ids|
        qualifying_user_ids(batch_user_ids, reference_time).each do |user_id|
          BadgeAchievement.create(
            user_id: user_id,
            badge_id: badge.id,
            rewarding_context_message_markdown: message,
          )
        end
      end
    end

    private

    attr_reader :weeks

    # Filters down to active recent authors who meet the article count floor and do not already hold the badge.
    def candidate_user_ids(badge, reference_time)
      recent_author_ids = Article.published
        .where("published_at > ? AND published_at <= ? AND score > ?",
               1.week.ago(reference_time), reference_time, MINIMUM_QUALITY)
        .select(:user_id)

      scope = User.where(id: recent_author_ids).where("articles_count >= ?", weeks)
      unless badge.allow_multiple_awards
        scope = scope.where(
          "NOT EXISTS (SELECT 1 FROM badge_achievements " \
          "WHERE badge_achievements.user_id = users.id AND badge_achievements.badge_id = ?)",
          badge.id,
        )
      end

      scope.ids
    end

    # Checks every week bucket in one grouped index-only SQL scan per batch instead of `weeks` queries per user.
    def qualifying_user_ids(batch_user_ids, reference_time)
      oldest_cutoff = weeks.weeks.ago(reference_time)
      bucket_cases = Array.new(weeks) do |i|
        num = i + 1
        ActiveRecord::Base.sanitize_sql_array(
          ["WHEN published_at > ? AND published_at < ? THEN ?",
           num.weeks.ago(reference_time), (num - 1).weeks.ago(reference_time), num],
        )
      end.join(" ")

      Article.where(published: true, user_id: batch_user_ids)
        .where("published_at > ? AND published_at < ?", oldest_cutoff, reference_time)
        .group(:user_id)
        .having("COUNT(DISTINCT CASE #{bucket_cases} END) = ?", weeks)
        .pluck(:user_id)
    end

    def generate_message
      return I18n.t("services.badges.award_streak.longest") if weeks == LONGEST_STREAK_WEEKS

      I18n.t("services.badges.award_streak.message", count: weeks * 2)
    end
  end
end
