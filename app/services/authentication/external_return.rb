module Authentication
  # Temporary bridge: remove with generic OIDC third-party initiated login (target_link_uri).
  class ExternalReturn
    CONTINUATION_PATTERN = /\A[A-Za-z0-9_\-]+\z/

    def self.redirect_url_for(omniauth_params)
      new(omniauth_params).redirect_url
    end

    def self.allowlisted_destination(url)
      new(nil).__send__(:allowlisted_url, url)
    end

    def initialize(omniauth_params)
      @omniauth_params = omniauth_params || {}
    end

    def redirect_url
      continuation = @omniauth_params["continuation"].to_s
      return unless continuation.match?(CONTINUATION_PATTERN)

      entry = configured_uri
      return unless entry

      "#{origin_of(entry)}#{entry.path}?continuation=#{continuation}"
    end

    private

    def allowlisted_url(value)
      return if value.blank?

      uri = Addressable::URI.parse(value.to_s.strip)
      return unless uri.scheme && uri.host

      allowed = configured_uri
      return unless allowed

      if allowed.scheme == uri.scheme &&
          allowed.host == uri.host &&
          normalized_port(allowed) == normalized_port(uri) &&
          uri.path == allowed.path && uri.userinfo.nil?
        "#{origin_of(allowed)}#{allowed.path}"
      end
    rescue Addressable::URI::InvalidURIError
      nil
    end

    # The receiving application owns the path; Forem only trusts this configured endpoint.
    def configured_uri
      return unless ENV.fetch("FOREM_EXTERNAL_RETURN_ENABLED", "false") == "true"

      uri = Addressable::URI.parse(ENV.fetch("FOREM_EXTERNAL_RETURN_URL", "").strip)
      return unless uri.scheme == "https" && uri.host.present? && uri.path.start_with?("/")
      return if uri.userinfo || uri.query || uri.fragment

      uri
    rescue Addressable::URI::InvalidURIError
      nil
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
