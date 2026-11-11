module EdgeCache
  class PurgeByKey
    MAX_KEYS_PER_REQUEST = 256
    REQUEST_TIMEOUT_SECONDS = 10

    def self.call(keys, soft: false, fallback_paths: nil)
      new.call(keys, soft: soft, fallback_paths: fallback_paths)
    end

    def call(keys, soft: false, fallback_paths: nil)
      if fastly_configured?
        normalized_keys = normalize_keys(keys)
        return if normalized_keys.empty?

        normalized_keys.each_slice(MAX_KEYS_PER_REQUEST) do |batch|
          purge_batch(batch, soft: soft)
        rescue StandardError => e
          report_error(e)
        end
      elsif fallback_paths.present?
        begin
          resolved_paths = fallback_paths.respond_to?(:call) ? fallback_paths.call : fallback_paths
          EdgeCache::Bust.call(resolved_paths) if resolved_paths.present?
        rescue StandardError => e
          report_error(e)
        end
      end
    end

    private

    def normalize_keys(keys)
      Array.wrap(keys).flatten.filter_map { |key| key.to_s.strip.presence }.uniq
    end

    def purge_batch(batch, soft:)
      response = HTTParty.post(
        "https://api.fastly.com/service/#{ApplicationConfig['FASTLY_SERVICE_ID']}/purge",
        headers: request_headers(soft: soft),
        body: { surrogate_keys: batch }.to_json,
        timeout: REQUEST_TIMEOUT_SECONDS,
      )
      log_failed_purge(batch, response) if response && !response.success?
    end

    def request_headers(soft:)
      headers = {
        "Fastly-Key" => ApplicationConfig["FASTLY_API_KEY"],
        "Accept" => "application/json",
        "Content-Type" => "application/json"
      }
      headers["Fastly-Soft-Purge"] = "1" if soft
      headers
    end

    def log_failed_purge(batch, response)
      ForemStatsClient.increment(
        "edgecache_purge_by_key.service_error",
        tags: ["status:#{response.code}"],
      )
      Rails.logger.warn(
        {
          message: "EdgeCache::PurgeByKey purge was rejected",
          surrogate_keys: batch,
          status: response.code,
          response_body: response.body.to_s.truncate(200)
        },
      )
    end

    def report_error(error)
      Rails.error.report(error)
      ForemStatsClient.increment(
        "edgecache_purge_by_key.service_error",
        tags: ["error_class:#{error.class}"],
      )
    end

    def fastly_configured?
      ApplicationConfig["FASTLY_API_KEY"].present? && ApplicationConfig["FASTLY_SERVICE_ID"].present?
    end
  end
end
