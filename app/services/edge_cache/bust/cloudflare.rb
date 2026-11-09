module EdgeCache
  class Bust
    class Cloudflare
      MAX_FILES_PER_REQUEST = 30

      def self.call(paths)
        cloudflare_purge(paths)
      end

      def self.cloudflare_purge(paths)
        target_urls = Array.wrap(paths).flat_map { |path| urls(path) }.uniq
        return [] if target_urls.empty?

        endpoint = "https://api.cloudflare.com/client/v4/zones/#{ApplicationConfig['CLOUDFLARE_ZONE_ID']}/purge_cache"
        target_urls.each_slice(MAX_FILES_PER_REQUEST).map do |batch|
          response = HTTParty.post(endpoint, headers: headers, body: { files: batch }.to_json)
          log_failed_purge(paths, batch, response) if response && !purge_accepted?(response)
          response
        rescue HTTParty::Error, SocketError, Errno::ECONNREFUSED, Timeout::Error => e
          ForemStatsClient.increment(
            "edgecache_bust.provider_error",
            tags: ["provider_class:EdgeCache::Bust::Cloudflare", "error_class:#{e.class}"],
          )
          Rails.logger.warn(
            {
              message: "EdgeCache::Bust::Cloudflare failed to purge",
              path: paths,
              urls: batch,
              error_class: e.class.name,
              error_message: e.message
            },
          )
          nil
        end
      end
      private_class_method :cloudflare_purge

      def self.headers
        {
          "Authorization" => "Bearer #{ApplicationConfig['CLOUDFLARE_API_TOKEN']}",
          "Content-Type" => "application/json",
          "User-Agent" => "#{Settings::Community.community_name} (#{URL.url})"
        }
      end
      private_class_method :headers

      def self.purge_accepted?(response)
        return false unless response.success?

        parsed = response.respond_to?(:parsed_response) ? response.parsed_response : nil
        return parsed["success"] != false if parsed.is_a?(Hash) && parsed.key?("success")

        true
      end
      private_class_method :purge_accepted?

      def self.log_failed_purge(path, batch, response)
        ForemStatsClient.increment(
          "edgecache_bust.provider_error",
          tags: ["provider_class:EdgeCache::Bust::Cloudflare", "status:#{response.code}"],
        )
        Rails.logger.warn(
          {
            message: "EdgeCache::Bust::Cloudflare purge was rejected",
            path: path,
            url: batch.first,
            urls: batch,
            status: response.code,
            response_body: response.body.to_s.truncate(200)
          },
        )
      end
      private_class_method :log_failed_purge

      def self.urls(path)
        return [] if path.blank?

        urls = [formatted_url(path)]
        urls << if path.include?("?")
                  formatted_url("#{path}&i=i")
                else
                  formatted_url("#{path}?i=i")
                end
        urls
      rescue Addressable::URI::InvalidURIError
        []
      end
      private_class_method :urls

      def self.formatted_url(path)
        if path.to_s.start_with?("http://", "https://")
          uri = Addressable::URI.parse(path)
          raise Addressable::URI::InvalidURIError if uri.host.blank?

          uri.normalize.to_s
        else
          URL.url(path)
        end
      end
      private_class_method :formatted_url
    end
  end
end
