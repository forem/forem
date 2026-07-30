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

      response = HTTParty.get(
        feed_url,
        timeout: 20,
        headers: { "User-Agent" => Feeds::Import::FEED_USER_AGENT }
      )

      return false unless response.success?

      xml = response.body.to_s
      return false if xml.blank?

      Feedjira.parse(xml)
      true
    rescue Feedjira::NoParserAvailable, StandardError
      false
    end

    private

    attr_reader :feed_url
  end
end