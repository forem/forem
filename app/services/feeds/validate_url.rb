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

      if [401, 403, 429].include?(response.code)
        raise StandardError,
              "Feed URL could not be retrieved — it may be protected by bot detection or temporarily unavailable"
      end

      return false unless response.success?

      Feedjira.parse(response.body)

      true
    rescue Feedjira::NoParserAvailable
      false
    end

    private

    attr_reader :feed_url
  end
end
