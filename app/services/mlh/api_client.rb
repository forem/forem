module Mlh
  # Thin transport for authenticated MLH v4 API calls.
  #
  # MLH_API_BASE_URL may be set to override the default API URL.
  class ApiClient
    Error = Class.new(StandardError)
    RecoverableError = Class.new(Error)
    ClientError = Class.new(Error)

    DEFAULT_BASE_URL = "https://api.mlh.com".freeze
    TIMEOUT_SECONDS = 10
    OPEN_TIMEOUT_SECONDS = 5
    RECOVERABLE_STATUSES = [408, 429].freeze

    # @param access_token [String] a MLH OAuth access token
    def initialize(access_token)
      @access_token = access_token
    end

    # @param path [String] an endpoint path with optional query string
    # @return [Hash] the parsed response body
    # @raise [ArgumentError] when no access token was given
    # @raise [RecoverableError] on a timeout / connection failure / 5xx
    # @raise [ClientError] on a permanent 4xx response or an unparseable body
    def get(path)
      raise ArgumentError, "access_token is required" if access_token.blank?

      url = "#{base_url}#{path}"
      response = Faraday.get(url) do |req|
        req.headers["Authorization"] = "Bearer #{access_token}"
        req.options.timeout = TIMEOUT_SECONDS
        req.options.open_timeout = OPEN_TIMEOUT_SECONDS
      end
      return JSON.parse(response.body) if response.success?

      raise_for_status(url, response.status)
    rescue Faraday::Error => e
      fail_with(RecoverableError, url, "#{e.class}: #{e.message}")
    rescue JSON::ParserError
      fail_with(ClientError, url, "unparseable response body")
    end

    private

    attr_reader :access_token

    def raise_for_status(url, status)
      recoverable = status >= 500 || RECOVERABLE_STATUSES.include?(status)
      error_class = recoverable ? RecoverableError : ClientError
      fail_with(error_class, url, "HTTP #{status}")
    end

    def fail_with(error_class, url, reason)
      Rails.logger.error("[Mlh::ApiClient] GET #{url} failed: #{reason}")
      raise error_class, reason
    end

    def base_url
      (ApplicationConfig["MLH_API_BASE_URL"].presence || DEFAULT_BASE_URL).chomp("/")
    end
  end
end
