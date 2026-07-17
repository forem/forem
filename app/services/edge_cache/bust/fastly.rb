module EdgeCache
  class Bust
    class Fastly
      # [@forem/systems] Fastly-enabled Forems don't need "flexible" domains.
      def self.call(path)
        fastly_purge(path)
      end

      def self.fastly_purge(path)
        headers = { "Fastly-Key" => ApplicationConfig["FASTLY_API_KEY"],
                    "User-Agent" => "#{Settings::Community.community_name} (#{URL.url})" }

        urls(path).map do |url|
          HTTParty.post("https://api.fastly.com/purge/#{url}", headers: headers)
        rescue HTTParty::Error, SocketError, Net::OpenTimeout, Net::ReadTimeout, Errno::ECONNREFUSED, Timeout::Error => e
          ForemStatsClient.increment(
            "edgecache_bust.provider_error",
            tags: ["provider_class:EdgeCache::Bust::Fastly", "error_class:#{e.class}"],
          )
          Rails.logger.warn(
            {
              message: "EdgeCache::Bust::Fastly failed to purge",
              path: path,
              url: url,
              error_class: e.class.name,
              error_message: e.message
            }
          )
          nil
        end
      end
      private_class_method :fastly_purge

      def self.urls(path)
        urls = [URL.url(path)]
        urls << if path.include?("?")
                  URL.url("#{path}&i=i")
                else
                  URL.url("#{path}?i=i")
                end
        urls
      rescue Addressable::URI::InvalidURIError
        []
      end
      private_class_method :urls
    end
  end
end
