module EdgeCache
  class Bust
    class Fastly
      # [@forem/systems] Fastly-enabled Forems don't need "flexible" domains.
      def self.call(path)
        api_key = ApplicationConfig["FASTLY_API_KEY"]

        fastly_purge(api_key, path)
      end

      def self.fastly_purge(api_key, path)
        fastly = ::Fastly.new(api_key: api_key)

        urls(path).map do |url|
          fastly.purge(url)
        end
      end
      private_class_method :fastly_purge

      def self.urls(path)
        [
          URL.url(path),
          URL.url("#{path}?i=i"),
        ]
      end
      private_class_method :fastly_purge
    end
  end
end
