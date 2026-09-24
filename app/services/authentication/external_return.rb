module Authentication
  # TEMPORARY: returns the browser to an external application after sign-in.
  #
  # Today this is the MLH Core round trip: Core starts sign-in with an opaque
  # `continuation` token and expects the browser back at FOREM_EXTERNAL_RETURN_URL
  # carrying that token. The standard replacement is OIDC third-party initiated
  # login with `target_link_uri`; when that ships, only this class (and the
  # parameter-filter entry) should need to change. See Authentication::MlhCoreBridge
  # for the removal checklist.
  #
  # Callers never inspect the wire format: `capture` turns the OmniAuth request
  # params into an opaque, session-safe context, and `resolve` turns that context
  # back into a redirect URL (or nil). Both are inert unless the bridge is
  # explicitly enabled.
  class ExternalReturn
    CONTINUATION_PATTERN = /\A[A-Za-z0-9_\-]+\z/

    # @return [Hash, nil] opaque context to carry across the interstitial
    def self.capture(omniauth_params)
      continuation = (omniauth_params || {})["continuation"].to_s
      return unless continuation.match?(CONTINUATION_PATTERN)

      { "continuation" => continuation }
    end

    # @return [String, nil] absolute URL to redirect to, or nil to fall through
    def self.resolve(context)
      new(context).redirect_url
    end

    # Convenience for the direct (non-interstitial) callback.
    def self.redirect_url_for(omniauth_params)
      resolve(capture(omniauth_params))
    end

    def initialize(context)
      @context = context || {}
    end

    def redirect_url
      continuation = @context["continuation"].to_s
      return unless continuation.match?(CONTINUATION_PATTERN)

      entry = configured_uri
      return unless entry

      "#{origin_of(entry)}#{entry.path}?continuation=#{continuation}"
    end

    private

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
      port = uri.port.nil? || uri.default_port == uri.port ? "" : ":#{uri.port}"
      "#{uri.scheme}://#{uri.host}#{port}"
    end
  end
end
