module Podcasts
  class GetMediaUrl
    HANDLED_ERRORS = [
      Addressable::URI::InvalidURIError,
      Net::OpenTimeout,
      SocketError,
      SystemCallError,
      URI::InvalidURIError,
      OpenSSL::SSL::SSLError,
    ].freeze

    TIMEOUT = 20

    def initialize(enclosure_url)
      @enclosure_url = enclosure_url.to_s
    end

    def self.call(...)
      new(...).call
    end

    def call
      was_http = !enclosure_url.starts_with?(/https/i)
      https_url = enclosure_url.sub(/http:/i, "https:")

      # check https url first
      if url_reachable?(https_url)
        reachable = true
        url = https_url
      # if https is unreachable, check http url (if it was provided)
      else
        reachable = was_http ? url_reachable?(enclosure_url) : false
        url = enclosure_url
      end
      result_struct.new(https: url.starts_with?(/https/i), reachable: reachable, url: url)
    end

    private

    attr_reader :enclosure_url

    def result_struct
      Struct.new(:https, :reachable, :url, keyword_init: true)
    end

    def url_reachable?(url)
      url = Addressable::URI.parse(url).normalize.to_s
      HTTParty.head(url, timeout: TIMEOUT).code == 200
    rescue *HANDLED_ERRORS
      false
    end
  end
end
