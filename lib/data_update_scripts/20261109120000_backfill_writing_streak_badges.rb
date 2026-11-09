module DataUpdateScripts
  # One-time backfill of the 4/8/16 week writing streak badges for every user
  # whose publishing history contains a qualifying streak.
  #
  # Thresholds whose badge does not exist yet are skipped, and the script then
  # raises so DataUpdateWorker marks it as failed (with the missing slugs in the
  # error) instead of succeeded. A succeeded script never runs again, which would
  # silently lose the backfill for badges registered later. Once the missing
  # badges are created, re-run the script from Admin > Data Update Scripts
  # ("Force Run"). Re-running is safe: users who already hold a badge are skipped.
  class BackfillWritingStreakBadges
    WEEKS = [4, 8, 16].freeze

    class MissingBadgesError < StandardError; end

    def run
      missing_slugs = WEEKS.filter_map do |weeks|
        service = Badges::AwardStreak.new(weeks: weeks, historical: true)
        service.badge_slug unless service.call
      end

      return if missing_slugs.empty?

      raise MissingBadgesError,
            "Streak badges not found: #{missing_slugs.join(', ')}. " \
            "Create them, then force-run this script to finish the backfill."
    end
  end
end
