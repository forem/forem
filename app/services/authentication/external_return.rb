module Authentication
  class ExternalReturn
    RETURN_PATH = "/web/auth/oauth/forem_returns".freeze

    CONTINUATION_PATTERN = /\A[A-Za-z0-9_\-]+\z/.freeze

    def self.redirect_url_for(omniauth_params)
      new(omniauth_params).redirect_url
    end

    def self.allowlisted_destination(url)
      new(nil).send(:allowlisted_url, url)
    end

    def initialize(omniauth_params)
      @omniauth_params = omniauth_params || {}
    end

    def redirect_url
      continuation = @omniauth_params["continuation"].to_s
      return nil unless continuation.match?(CONTINUATION_PATTERN)

      entry = allowed_uris.find { |uri| uri.path == RETURN_PATH }
      return nil unless entry

      "#{origin_of(entry)}#{RETURN_PATH}?continuation=#{continuation}"
    end

    private

    def allowlisted_url(value)
      return nil if value.blank?

      uri = Addressable::URI.parse(value.to_s.strip)
      return nil unless uri.scheme && uri.host

      allowed_uris.find do |allowed|
        allowed.scheme == uri.scheme &&
          allowed.host == uri.host &&
          normalized_port(allowed) == normalized_port(uri) &&
          uri.path == RETURN_PATH
      end && "#{uri.scheme}://#{uri.host}#{port_suffix(uri)}#{RETURN_PATH}"
    rescue Addressable::URI::InvalidURIError
      nil
    end

    def allowed_uris
      @allowed_uris ||= ENV.fetch("FOREM_EXTERNAL_RETURN_ORIGINS", "")
        .split(",")
        .map { |entry| Addressable::URI.parse(entry.strip) }
        .select { |uri| uri.scheme == "https" && uri.host.present? }
    rescue Addressable::URI::InvalidURIError
      []
    end

    def origin_of(uri)
      "#{uri.scheme}://#{uri.host}#{port_suffix(uri)}"
    end

    def port_suffix(uri)
      default_port?(uri) ? "" : ":#{uri.port}"
    end

    def normalized_port(uri)
      default_port?(uri) ? nil : uri.port
    end

    def default_port?(uri)
      uri.port.nil? || uri.default_port == uri.port
    end
  end
end
