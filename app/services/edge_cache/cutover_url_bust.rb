module EdgeCache
  # Temporary deploy cutover bridge for routes that newly gained `Surrogate-Key`
  # headers in PR #24746 (e.g. legacy 301 slug redirects, `/bottom_items`, `/tags`,
  # `/async_info/navigation_links`, tag feeds, podcast index, and org articles).
  #
  # Pre-deploy cached objects on those routes may sit at Fastly without the new
  # `Surrogate-Key` until their 24h `max-age` (+ 24h `stale-if-error`) expires.
  # During the first 50 hours after deploy, this helper supplements `PurgeByKey`
  # by enqueuing targeted URL busts via `EdgeCache::CutoverUrlBustWorker`, then
  # automatically becomes a zero-Redis-read no-op once the window elapses.
  #
  # Safe to delete (along with `CutoverUrlBustWorker` and its call sites) 50+ hours
  # after PR #24746 deploys to production.
  module CutoverUrlBust
    CACHE_KEY = "edge_cache:surrogate_cutover_started_at".freeze
    WINDOW_DURATION = 50.hours
    HARD_CUTOFF_AT = Time.utc(2026, 11, 25).freeze
    BATCH_SIZE = 50

    module_function

    def call(paths, delay: nil)
      return unless active?

      resolved = paths.respond_to?(:call) ? paths.call : paths
      normalized = normalize_paths(resolved)
      return if normalized.empty?

      normalized.each_slice(BATCH_SIZE) do |batch|
        if delay
          EdgeCache::CutoverUrlBustWorker.perform_in(delay, batch)
        else
          EdgeCache::CutoverUrlBustWorker.perform_async(batch)
        end
      end
    rescue StandardError => e
      Rails.error.report(e)
    end

    def purge_now(paths)
      return unless fastly_configured?

      normalize_paths(paths).each do |path|
        EdgeCache::Bust::Fastly.call(path)
      rescue StandardError => e
        Rails.error.report(e)
      end
    end

    def active?
      return false unless fastly_configured?

      override = ApplicationConfig["EDGE_CACHE_CUTOVER_URL_BUST"]
      return override == "true" if override.in?(%w[true false])
      return false if Time.current >= HARD_CUTOFF_AT

      (Time.current.to_i - cutover_started_at) < WINDOW_DURATION.to_i
    rescue StandardError => e
      Rails.error.report(e)
      false
    end

    def reset!
      @cached_started_at = nil
    end

    def fastly_configured?
      ApplicationConfig["FASTLY_API_KEY"].present? && ApplicationConfig["FASTLY_SERVICE_ID"].present?
    end

    def cutover_started_at
      now = Time.current.to_i
      if defined?(@cached_started_at) && @cached_started_at && now >= @cached_started_at
        return @cached_started_at
      end

      @cached_started_at = Rails.cache.fetch(CACHE_KEY, expires_in: 30.days) { now }.to_i
    end

    def normalize_paths(paths)
      Array.wrap(paths).flatten.filter_map { |path| path.to_s.strip.presence }.uniq
    end
  end
end
