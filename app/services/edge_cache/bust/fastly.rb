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
        end
      end
      private_class_method :fastly_purge

      def self.urls(path)
        [
          URL.url(path),
          URL.url("#{path}?i=i"),
        ]
      end
      private_class_method :urls
    end
  end
end
