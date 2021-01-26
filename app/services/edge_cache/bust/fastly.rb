module EdgeCache
  class Bust
    class Fastly
      def self.call(path)
        # TODO: (Alex Smith) - It would be "nice to have" the ability to use the
        # Fastly gem here instead of custom API calls.

        # @forem/systems Fastly-enabled forems don't need "flexible" domains.
        HTTParty.post(
          "https://api.fastly.com/purge/https://#{URL.domain}#{path}",
          headers: {
            "Fastly-Key" => ApplicationConfig["FASTLY_API_KEY"]
          },
        )
        HTTParty.post(
          "https://api.fastly.com/purge/https://#{URL.domain}#{path}?i=i",
          headers: {
            "Fastly-Key" => ApplicationConfig["FASTLY_API_KEY"]
          },
        )
      end
    end
  end
end
