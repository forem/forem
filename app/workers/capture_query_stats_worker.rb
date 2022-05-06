class CaptureQueryStatsWorker
  include Sidekiq::Job

  def perform
    return unless ENV.fetch("PG_HERO_CAPTURE_QUERY_STATS", nil) == "true"

    PgHero.capture_query_stats
  end
end
