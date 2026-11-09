module EdgeCache
  class PurgeByKey
    MAX_TAGS_PER_REQUEST = 30

    def self.call(keys, soft: false, fallback_paths: nil)
      new.call(keys, soft: soft, fallback_paths: fallback_paths)
    end

    def call(keys, soft: false, fallback_paths: nil)
      normalized_keys = Array.wrap(keys).flatten.compact
      if service
        normalized_keys.each do |key|
          service.purge_by_key(key, soft)
        rescue StandardError => e
          report_error(e)
        end
      elsif cloudflare_configured?
        purge_cloudflare_tags(normalized_keys, fallback_paths: fallback_paths)
      elsif fallback_paths.present?
        purge_fallback_paths(fallback_paths)
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

    def cloudflare_configured?
      ApplicationConfig["CLOUDFLARE_API_TOKEN"].present? && ApplicationConfig["CLOUDFLARE_ZONE_ID"].present?
    end

    def purge_cloudflare_tags(keys, fallback_paths: nil)
      return if keys.empty?

      endpoint = "https://api.cloudflare.com/client/v4/zones/#{ApplicationConfig['CLOUDFLARE_ZONE_ID']}/purge_cache"
      failed = false

      keys.uniq.each_slice(MAX_TAGS_PER_REQUEST) do |batch|
        response = HTTParty.post(
          endpoint,
          headers: cloudflare_headers,
          body: { tags: batch }.to_json,
        )
        unless response&.success?
          failed = true
          ForemStatsClient.increment(
            "edgecache_purge_by_key.service_error",
            tags: ["provider:cloudflare", "status:#{response&.code}"],
          )
        end
      rescue StandardError => e
        failed = true
        report_error(e)
      end

      purge_fallback_paths(fallback_paths) if failed && fallback_paths.present?
    end

    def cloudflare_headers
      {
        "Authorization" => "Bearer #{ApplicationConfig['CLOUDFLARE_API_TOKEN']}",
        "Content-Type" => "application/json",
        "User-Agent" => "#{Settings::Community.community_name} (#{URL.url})"
      }
    end

    def purge_fallback_paths(fallback_paths)
      EdgeCache::Bust.call(fallback_paths)
    rescue StandardError => e
      report_error(e)
    end

    def report_error(error)
      Rails.error.report(error)
      ForemStatsClient.increment(
        "edgecache_purge_by_key.service_error",
        tags: ["error_class:#{error.class}"],
      )
    end
  end
end
