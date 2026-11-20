require "cgi"
require "digest"

module EdgeFeed
  # Low-resource Fastly KV Store HTTP client for mirroring custom home-feed data.
  #
  # Writes are deduplicated via SHA-256 digests cached in `Rails.cache` so unchanged
  # snapshots, card shards, embeddings, and user profiles incur zero KV write API calls.
  class KvClient
    API_BASE = "https://api.fastly.com/resources/stores/kv".freeze
    DIGEST_CACHE_TTL = 6.hours
    REQUEST_TIMEOUT = 10

    def self.configured?
      ApplicationConfig["FASTLY_API_KEY"].present? &&
        ApplicationConfig["FASTLY_FEED_KV_STORE_ID"].present?
    end

    def initialize(
      api_key: ApplicationConfig["FASTLY_API_KEY"],
      store_id: ApplicationConfig["FASTLY_FEED_KV_STORE_ID"],
      cache: Rails.cache
    )
      @api_key = api_key
      @store_id = store_id
      @cache = cache
    end

    def configured?
      @api_key.present? && @store_id.present?
    end

    # Uploads `value` to `key` in Fastly KV Store unless its SHA-256 matches the last
    # successfully written digest (when `deduplicate: true`).
    #
    # Returns `:written`, `:unchanged`, `:unconfigured`, or `:error`.
    def put(key, value, deduplicate: true)
      return :unconfigured unless configured?

      body = value.is_a?(String) ? value : JSON.generate(value)
      digest = Digest::SHA256.hexdigest(body)
      cache_key = digest_cache_key(key)

      return :unchanged if deduplicate && @cache.read(cache_key) == digest

      response = HTTParty.put(
        key_url(key),
        headers: request_headers("Content-Type" => "application/json; charset=utf-8"),
        body: body,
        timeout: REQUEST_TIMEOUT,
      )

      if response.success?
        @cache.write(cache_key, digest, expires_in: DIGEST_CACHE_TTL) if deduplicate
        ForemStatsClient.increment("edge_feed.kv.write", tags: ["status:ok"])
        :written
      else
        log_failure("put", key, status: response.code, body: response.body)
        :error
      end
    rescue HTTParty::Error, SocketError, Errno::ECONNREFUSED, Timeout::Error => e
      log_exception("put", key, e)
      :error
    end

    def delete(key)
      return :unconfigured unless configured?

      response = HTTParty.delete(
        key_url(key),
        headers: request_headers,
        timeout: REQUEST_TIMEOUT,
      )

      if response.success? || response.code == 404
        @cache.delete(digest_cache_key(key))
        :deleted
      else
        log_failure("delete", key, status: response.code, body: response.body)
        :error
      end
    rescue HTTParty::Error, SocketError, Errno::ECONNREFUSED, Timeout::Error => e
      log_exception("delete", key, e)
      :error
    end

    private

    def key_url(key)
      "#{API_BASE}/#{CGI.escape(@store_id.to_s)}/keys/#{CGI.escape(key.to_s)}"
    end

    def digest_cache_key(key)
      "edge_feed:kv_sha256:#{@store_id}:#{key}"
    end

    def request_headers(extra = {})
      {
        "Fastly-Key" => @api_key,
        "User-Agent" => "ForemEdgeFeedMirror/1.0"
      }.merge(extra)
    end

    def log_failure(action, key, status:, body:)
      ForemStatsClient.increment("edge_feed.kv.#{action}_error", tags: ["status:#{status}"])
      Rails.logger.warn(
        {
          message: "EdgeFeed::KvClient #{action} rejected",
          key: key,
          status: status,
          response_body: body.to_s.truncate(200)
        },
      )
    end

    def log_exception(action, key, error)
      ForemStatsClient.increment("edge_feed.kv.#{action}_error", tags: ["error_class:#{error.class}"])
      Rails.logger.warn(
        {
          message: "EdgeFeed::KvClient #{action} failed",
          key: key,
          error_class: error.class.name,
          error_message: error.message
        },
      )
    end
  end
end
