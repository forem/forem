module Feeds
  class ValidateUrl
    NETWORK_ERRORS = [
      SocketError,
      Net::OpenTimeout,
      Net::ReadTimeout,
      Timeout::Error,
      OpenSSL::SSL::SSLError,
      Errno::ECONNREFUSED,
      Errno::EHOSTUNREACH,
      Errno::ECONNRESET,
      URI::InvalidURIError,
      HTTParty::Error,
    ].freeze

    def self.call(feed_url)
      new(feed_url).call
    end

    def initialize(feed_url)
      @feed_url = feed_url.to_s.strip
    end

    def call
      return false if feed_url.blank?

      response = HTTParty.get(feed_url,
                              timeout: 20,
                              headers: { "User-Agent" => Feeds::Import::FEED_USER_AGENT })

      unless response.success?
        message = case response.code
                  when 401, 403, 429
                    I18n.t("feeds.validate_url.bot_protection")
                  when 404
                    I18n.t("feeds.validate_url.not_found")
                  when 500
                    I18n.t("feeds.validate_url.server_error")
                  else
                    I18n.t("feeds.validate_url.status_error", code: response.code)
                  end
        raise StandardError, message
      end

      Feedjira.parse(response.body)

      true
    rescue Feedjira::NoParserAvailable
      false
    rescue *NETWORK_ERRORS => e
      Rails.logger.warn("Feeds::ValidateUrl network error for #{feed_url}: #{e.class} - #{e.message}")
      raise StandardError, I18n.t("feeds.validate_url.network_error")
    end

    private

    attr_reader :feed_url
  end
end
