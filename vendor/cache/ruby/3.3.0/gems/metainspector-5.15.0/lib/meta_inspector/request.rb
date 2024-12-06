require 'faraday'
require 'faraday-cookie_jar'
require 'faraday-http-cache'
require 'faraday/encoding'
require 'faraday/follow_redirects'
require 'faraday/gzip'
require 'faraday/retry'
require 'timeout'

module MetaInspector

  # Makes the request to the server
  class Request
    def initialize(initial_url, options = {})
      @url                = initial_url

      fail MetaInspector::RequestError.new('URL must be HTTP') unless @url.url =~ /http[s]?:\/\//i

      @allow_redirections = options[:allow_redirections]
      @connection_timeout = options[:connection_timeout]
      @read_timeout       = options[:read_timeout]
      @retries            = options[:retries]
      @encoding           = options[:encoding]
      @headers            = options[:headers]
      @faraday_options    = options[:faraday_options] || {}
      @faraday_http_cache = options[:faraday_http_cache]

      response            # request early so we can fail early
    end

    extend Forwardable
    delegate :url => :@url

    def read
      return unless response
      body = response.body
      body = body.encode!(@encoding, @encoding, :invalid => :replace) if @encoding
      body.tr("\000", '')
    rescue ArgumentError => e
      raise MetaInspector::RequestError.new(e)
    end

    def content_type
      return nil if response.headers['content-type'].nil?
      response.headers['content-type'].split(';')[0] if response
    end

    def response
      @response ||= fetch
    rescue Faraday::TimeoutError => e
      raise MetaInspector::TimeoutError.new(e)
    rescue Faraday::ConnectionFailed, Faraday::SSLError, URI::InvalidURIError, Faraday::FollowRedirects::RedirectLimitReached => e
      raise MetaInspector::RequestError.new(e)
    end

    private

    def fetch
      Timeout::timeout(fatal_timeout) do
        @faraday_options.merge!(:url => url)
        follow_redirects_options = @faraday_options.delete(:redirect) || {}

        session = Faraday.new(@faraday_options) do |faraday|
          faraday.request :retry, max: @retries

          faraday.request :gzip

          if @allow_redirections
            follow_redirects_options[:limit] ||= 10
            faraday.use Faraday::FollowRedirects::Middleware, **follow_redirects_options
            faraday.use :cookie_jar
          end

          if @faraday_http_cache.is_a?(Hash)
            @faraday_http_cache[:serializer] ||= Marshal
            faraday.use Faraday::HttpCache, **@faraday_http_cache
          end

          faraday.headers.merge!(@headers || {})
          faraday.response :encoding
          faraday.adapter :net_http
        end

        response = session.get do |req|
          req.options.timeout      = @connection_timeout
          req.options.open_timeout = @read_timeout
        end

        if @allow_redirections
          @url.url = response.env.url.to_s
        end

        response
      end
    rescue Timeout::Error => e
      raise MetaInspector::TimeoutError.new(e)
    end

    # Timeouts when connecting / reading a request are handled by Faraday, but in the
    # case of URLs that respond with streaming, Faraday will never return. In that case,
    # we'll resort to our own timeout
    #
    # https://github.com/jaimeiniesta/metainspector/issues/188
    # https://github.com/lostisland/faraday/issues/602
    #
    def fatal_timeout
      (@connection_timeout || 0) + (@read_timeout || 0) + 1
    end
  end
end
