class CaptureQueryStatsWorker
  include Sidekiq::Job

  def perform
    return unless ENV["PG_HERO_CAPTURE_QUERY_STATS"] == "true"

    PgHero.capture_query_stats
  end
end
