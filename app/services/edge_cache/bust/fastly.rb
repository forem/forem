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
          clean_url = url.to_s.sub(%r{\Ahttps?://}, "")
          HTTParty.post("https://api.fastly.com/purge/#{clean_url}", headers: headers)
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
