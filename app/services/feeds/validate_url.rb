module Feeds
  class ValidateUrl
    def self.call(feed_url)
      new(feed_url).call
    end

    def initialize(feed_url)
      @feed_url = feed_url
    end

    def call
      return false if feed_url.blank?

      response = HTTParty.get(feed_url,
                             timeout: 20,
                             headers: { "User-Agent" => Feeds::Import::FEED_USER_AGENT })

      unless response.success?
        message = case response.code
                  when 401, 403, 429
                    "Feed URL could not be retrieved — it may be protected by bot detection or temporarily unavailable"
                  when 404
                    "Feed URL could not be retrieved — the server returned a 404 (Not Found)"
                  when 500
                    "Feed URL could not be retrieved — the server returned a 500 (Internal Server Error)"
                  else
                    "Feed URL could not be retrieved — the server returned status code #{response.code}"
                  end
        raise StandardError, message
      end

      Feedjira.parse(response.body)

      true
    rescue Feedjira::NoParserAvailable
      false
    end

    private

    attr_reader :feed_url
  end
end
