module Badges
  # Awards the "N week streak" writing badges.
  #
  # A streak is a run of N consecutive calendar weeks (weeks start on Monday,
  # UTC) in which the user published at least one post. Calendar weeks are used
  # rather than rolling 7 day windows so that someone who publishes "once a
  # week" is not penalised when their posts drift a few hours either way.
  #
  # By default only active streaks are rewarded (the run must include the
  # current or the previous calendar week). Pass `historical: true` to reward
  # any run in the user's history, which is used to backfill past writers.
  class AwardStreak
    LONGEST_STREAK_WEEKS = 16

    MINIMUM_QUALITY = -25

    def self.call(weeks:, historical: false)
      new(weeks: weeks, historical: historical).call
    end

    def initialize(weeks:, historical: false)
      @weeks = weeks
      @historical = historical
    end

    def call
      badge_slug = "#{weeks}-week-streak"
      return unless (badge_id = Badge.id_for_slug(badge_slug))

      message = generate_message

      User.where(id: qualifying_user_ids(badge_id)).find_each do |user|
        user.badge_achievements.create(
          badge_id: badge_id,
          rewarding_context_message_markdown: message,
        )
      rescue StandardError => e
        # One bad user must not stop everybody after them from being rewarded.
        Rails.error.report(e)
      end
    end

    private

    attr_reader :weeks, :historical

    # Gaps-and-islands: subtracting a per-user row number (in days) from each
    # week start gives the same value for all weeks in a consecutive run.
    # No credit for super low quality posts.
    def qualifying_user_ids(badge_id)
      recent_clause = historical ? "" : "AND MAX(week_start) >= (date_trunc('week', now())::date - 7)"

      sql = <<~SQL.squish
        SELECT user_id
        FROM (
          SELECT user_id,
                 week_start,
                 week_start - (ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY week_start) * 7)::int AS run_id
          FROM (
            SELECT DISTINCT user_id, date_trunc('week', published_at)::date AS week_start
            FROM articles
            WHERE published = TRUE
              AND published_at <= now()
              AND score > #{MINIMUM_QUALITY.to_i}
          ) weekly
        ) runs
        WHERE NOT EXISTS (
          SELECT 1 FROM badge_achievements
          WHERE badge_achievements.user_id = runs.user_id
            AND badge_achievements.badge_id = #{badge_id.to_i}
        )
        GROUP BY user_id, run_id
        HAVING COUNT(*) >= #{weeks.to_i} #{recent_clause}
      SQL

      ActiveRecord::Base.connection.select_values(sql).uniq
    end

    def generate_message
      return I18n.t("services.badges.award_streak.longest") if weeks == LONGEST_STREAK_WEEKS

      I18n.t("services.badges.award_streak.message", count: weeks * 2)
    end
  end
end
