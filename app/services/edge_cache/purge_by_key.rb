module EdgeCache
  class PurgeByKey
    def self.call(keys, soft: false, fallback_paths: nil)
      new.call(keys, soft: soft, fallback_paths: fallback_paths)
    end

    def call(keys, soft: false, fallback_paths: nil)
      if service
        Array.wrap(keys).flatten.compact.each do |key|
          service.purge_by_key(key, soft)
        rescue StandardError => e
          Honeybadger.notify(e)
          ForemStatsClient.increment(
            "edgecache_purge_by_key.service_error",
            tags: ["error_class:#{e.class}"],
          )
        end
      elsif fallback_paths.present?
        begin
          EdgeCache::Bust.call(fallback_paths)
        rescue StandardError => e
          Honeybadger.notify(e)
          ForemStatsClient.increment(
            "edgecache_purge_by_key.service_error",
            tags: ["error_class:#{e.class}"],
          )
        end
      end
    end

    private

    def service
      return unless fastly_configured?

      fastly = Fastly.new(api_key: ApplicationConfig["FASTLY_API_KEY"])
      Fastly::Service.new({ id: ApplicationConfig["FASTLY_SERVICE_ID"] }, fastly)
    end

    def fastly_configured?
      ApplicationConfig["FASTLY_API_KEY"].present? && ApplicationConfig["FASTLY_SERVICE_ID"].present?
    end
  end
end
