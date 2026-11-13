module DataUpdateScripts
  # One-time backfill of the 4/8/16 week writing streak badges for every user
  # whose publishing history contains a qualifying streak.
  #
  # Streak badges are optional, so thresholds without a badge are skipped and
  # logged and the script still succeeds. Admins who create streak badges later
  # can backfill at any time with `rake award_streak_badges_backfill`.
  #
  # If individual awards error (e.g. a transient DB/Redis outage), the service
  # raises Badges::AwardStreak::IncompleteError after attempting everyone, so
  # this script is marked failed instead of succeeded and can be re-run with
  # Force Run or the rake task. Re-running only awards users still missing the
  # badge.
  class BackfillWritingStreakBadges
    # Entry point called by DataUpdateWorker.
    def run
      Badges::AwardStreak.backfill
    end
  end
end
