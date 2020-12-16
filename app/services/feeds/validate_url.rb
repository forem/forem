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

      xml = HTTParty.get(feed_url, timeout: 10).body
      Feedjira.parse(xml)

      true
    rescue Feedjira::NoParserAvailable
      false
    end

    private

    attr_reader :feed_url
  end
end
