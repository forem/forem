module Badges
  # Awards the "N week streak" writing badges.
  #
  # A streak is a run of N consecutive calendar weeks (weeks start on Monday,
  # UTC) in which the user published at least one post. Calendar weeks are used
  # rather than rolling 7 day windows so that someone who publishes "once a
  # week" is not penalised when their posts drift within the week (e.g. Monday
  # one week and Sunday the next).
  #
  # By default only active streaks are rewarded (the run must include the
  # current or the previous calendar week). Pass `historical: true` to reward
  # any run in the user's history, which is used to backfill past writers.
  class AwardStreak
    LONGEST_STREAK_WEEKS = 16

    MINIMUM_QUALITY = -25

    # Communities have registered these badges under either slug, so look up
    # the descriptive one first and fall back to the original short one.
    SLUG_FORMATS = ["%<weeks>d-week-writing-streak", "%<weeks>d-week-streak"].freeze

    BACKFILL_WEEKS = [4, 8, 16].freeze

    # Bounds the IN (...) list sent per query; historical runs can qualify
    # thousands of users.
    BATCH_SIZE = 1_000

    # Generous ceiling for the one-time full-history scan, which would otherwise
    # hit the 2,500ms default statement_timeout (config/database.yml).
    HISTORICAL_STATEMENT_TIMEOUT = 5.minutes

    # Raised by historical runs when some awards errored, so a one-time backfill
    # is not recorded as complete while writers are still unrewarded.
    class IncompleteError < StandardError; end

    def self.call(weeks:, historical: false)
      new(weeks: weeks, historical: historical).call
    end

    # Rewards every historical streak for each configured threshold. Streak
    # badges are optional admin-created records, so thresholds without a badge
    # are skipped and logged rather than treated as errors. Idempotent: users
    # who already hold a badge are skipped, so this is safe to re-run whenever
    # new streak badges are created.
    #
    # Every threshold is attempted even if an earlier one hits per-user errors;
    # those errors are then raised together as IncompleteError.
    #
    # Returns the thresholds (weeks) whose badge was not found.
    def self.backfill(weeks_list: BACKFILL_WEEKS)
      missing = []
      incomplete = []

      weeks_list.each do |weeks|
        missing << weeks unless call(weeks: weeks, historical: true)
      rescue IncompleteError => e
        incomplete << e.message
      end

      if missing.any?
        slugs = missing.flat_map { |weeks| new(weeks: weeks).candidate_slugs }
        Rails.logger.info("[Badges::AwardStreak] Badge slugs not found: #{slugs.join(', ')}")
      end

      raise IncompleteError, incomplete.join("; ") if incomplete.any?

      missing
    end

    def initialize(weeks:, historical: false)
      @weeks = weeks
      @historical = historical
    end

    # Returns false when no badge exists for this threshold (nothing was
    # awarded), true once the awarding pass has run.
    #
    # Per-user errors are reported and skipped so one bad record cannot block
    # everyone after it. Recurring runs retry those users on their next pass,
    # but a historical run raises IncompleteError afterwards so callers (the
    # data update script, the rake task) do not treat it as finished.
    def call
      return false unless (badge_id = find_badge_id)

      message = generate_message
      failed_user_ids = []

      qualifying_user_ids(badge_id).each_slice(BATCH_SIZE) do |user_ids|
        eligible_users(user_ids).each do |user|
          next if user.banished?

          user.badge_achievements.create(
            badge_id: badge_id,
            rewarding_context_message_markdown: message,
          )
        rescue StandardError => e
          failed_user_ids << user.id
          Rails.error.report(e, context: { badge_id: badge_id, user_id: user.id })
        end
      end

      if historical && failed_user_ids.any?
        raise IncompleteError,
              "#{weeks} week streak: #{failed_user_ids.size} award(s) failed " \
              "(user ids: #{failed_user_ids.first(20).join(', ')}#{', ...' if failed_user_ids.size > 20})"
      end

      true
    end

    def candidate_slugs
      SLUG_FORMATS.map { |pattern| format(pattern, weeks: weeks) }
    end

    private

    attr_reader :weeks, :historical

    def find_badge_id
      candidate_slugs.each do |slug|
        badge_id = Badge.id_for_slug(slug)
        return badge_id if badge_id
      end
      nil
    end

    # Excludes spam and suspended accounts in SQL (same guard as
    # Badges::AwardFirstPost) instead of a per-user spam_or_suspended? check,
    # which would cost a roles query for every qualifying user. Banished users
    # are skipped in #call, as in Badges::Award.
    def eligible_users(user_ids)
      User.where(id: user_ids)
        .where.not(id: User.with_role(:spam).or(User.with_role(:suspended)))
    end

    def qualifying_user_ids(badge_id)
      sql = qualifying_user_ids_sql(badge_id)
      connection = ApplicationRecord.connection

      if historical
        ApplicationRecord.with_statement_timeout(HISTORICAL_STATEMENT_TIMEOUT) { connection.select_values(sql) }
      else
        connection.select_values(sql)
      end
    end

    # Gaps-and-islands: subtracting a per-user row number (in weeks) from each
    # week start gives the same value for all weeks in a consecutive run.
    # No credit for super low quality posts.
    #
    # Recurring runs only reward streaks that include the current or previous
    # calendar week, so they are bounded twice:
    #   * active_authors limits the scan to users with a qualifying post since
    #     the start of the previous week (index on published_at, score), and
    #   * their history is only read back to current_week_start - weeks * 7
    #     days, i.e. the current week plus the `weeks` weeks before it. Any run
    #     of at least `weeks` weeks ending in the current or previous week fits
    #     in that window, so the result is the same as a full-history scan.
    # Historical runs scan everything (under a raised statement_timeout).
    #
    # The badge_achievements check runs only for users who achieved a streak,
    # not for every weekly row. Times are bound from Time.current.utc rather
    # than Postgres now(): articles.published_at is a UTC timestamp without
    # time zone, so this never depends on the session TimeZone and follows
    # Timecop/travel_to in specs.
    def qualifying_user_ids_sql(badge_id)
      connection = ApplicationRecord.connection
      now = Time.current.utc
      current_week_start = now.beginning_of_week(:monday)
      previous_week_start = current_week_start - 1.week
      history_start = current_week_start - weeks.to_i.weeks

      quality_filter = <<~SQL.squish
        published = TRUE
          AND published_at <= #{connection.quote(now)}
          AND score > #{MINIMUM_QUALITY.to_i}
      SQL

      active_authors_cte, history_filter, recent_having =
        if historical
          ["", "", ""]
        else
          [
            <<~SQL.squish,
              active_authors AS (
                SELECT DISTINCT user_id FROM articles
                WHERE #{quality_filter}
                  AND published_at >= #{connection.quote(previous_week_start)}
              ),
            SQL
            "AND published_at >= #{connection.quote(history_start)} " \
            "AND user_id IN (SELECT user_id FROM active_authors)",
            "AND MAX(week_start) >= #{connection.quote(previous_week_start.to_date)}",
          ]
        end

      <<~SQL.squish
        WITH #{active_authors_cte}
        weekly AS (
          SELECT DISTINCT user_id, date_trunc('week', published_at)::date AS week_start
          FROM articles
          WHERE #{quality_filter} #{history_filter}
        ),
        runs AS (
          SELECT user_id,
                 week_start,
                 week_start - (ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY week_start) * 7)::int AS run_id
          FROM weekly
        ),
        streakers AS (
          SELECT DISTINCT user_id
          FROM runs
          GROUP BY user_id, run_id
          HAVING COUNT(*) >= #{weeks.to_i} #{recent_having}
        )
        SELECT streakers.user_id
        FROM streakers
        WHERE NOT EXISTS (
          SELECT 1 FROM badge_achievements
          WHERE badge_achievements.user_id = streakers.user_id
            AND badge_achievements.badge_id = #{badge_id.to_i}
        )
        ORDER BY streakers.user_id
      SQL
    end

    def generate_message
      return I18n.t("services.badges.award_streak.longest") if weeks == LONGEST_STREAK_WEEKS

      I18n.t("services.badges.award_streak.message", count: weeks * 2)
    end
  end
end
