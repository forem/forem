module Emails
  # The rules for turning a link into an Ahoy-tracked click URL, in one place.
  #
  # Two callers need them and must agree exactly, because
  # Ahoy::EmailClicksController#verify_signature rejects anything that does not
  # match byte for byte:
  #
  #   - the AhoyEmail::Processor patch in config/initializers/ahoy_email.rb,
  #     which rewrites the rendered body on the SMTP path
  #   - Emails::AhoyLinkDecorator, which rewrites the Customer.io message_data
  #     payload, since Customer.io renders its own template and never sees that
  #     body
  #
  module AhoyLinkTracking
    module_function

    def trackable?(uri)
      uri&.absolute? && %w[http https].include?(uri.scheme)
    end

    def parse_uri(href)
      Addressable::URI.heuristic_parse(href.to_s)
    rescue StandardError
      nil
    end

    def internal?(uri)
      uri.host == Settings::General.app_domain
    end

    # Mirrors AhoyEmail::Processor#skip_attribute?, which refuses to rewrite
    # unsubscribe links so a tracking failure can never block an opt-out.
    def unsubscribe?(href)
      href.to_s.match?(/unsubscribe/i)
    end

    # A tracked URL pasted back into stored content (a billboard, a survey body)
    # arrives here looking like an ordinary internal link. Decorating it again
    # appends a second t/s/u set, and because Rack resolves duplicate params to
    # the last value, the engine redirect verifies the outer signature and
    # forwards to itself -- a loop. Leave anything already carrying tracking
    # alone.
    def already_tracked?(uri, href)
      return true if href.to_s.include?("ahoy_click=true")

      internal?(uri) && uri.path.to_s.start_with?("/ahoy/")
    end

    def skip?(uri, href)
      unsubscribe?(href) || already_tracked?(uri, href)
    end

    ALLOWED_EXTERNAL_URL_OPTION_KEYS = [:host, :protocol, :port, "host", "protocol", "port"].freeze
    ALLOWED_HTTP_SCHEMES = %w[http https].freeze

    def native_signing_available?
      return false if AhoyEmail.secret_token.blank?

      loc = AhoyEmail::Utils.method(:signature).source_location
      loc.is_a?(Array) && loc[0].to_s.end_with?("/ahoy_email/utils.rb")
    end

    # Resolves standard `{ host:, protocol:, port: }` options into the mounted
    # `/ahoy/click` base URL once per payload, returning `nil` for non-standard
    # options so external links defer to `AhoyEmail::Engine.routes.url_helpers.url_for`.
    def external_base_url(url_options)
      return unless url_options.is_a?(Hash) && url_options.any?
      return unless url_options.keys.all? { |k| ALLOWED_EXTERNAL_URL_OPTION_KEYS.include?(k) }
      return if url_options[:protocol] == false || url_options["protocol"] == false

      host_str = (url_options[:host] || url_options["host"]).to_s
      return if host_str.empty? || host_str.match?(/[\s?#@]/)

      protocol = url_options[:protocol] || url_options["protocol"]
      port = url_options[:port] || url_options["port"]
      build_external_base_url(host_str, protocol, port)
    end

    def build_external_base_url(host_str, protocol, port)
      if host_str.start_with?("http://", "https://")
        return if protocol.present? || port.present?

        trimmed = host_str.chomp("/")
        return if trimmed.index("/", trimmed.index("://") + 3)

        return "#{trimmed}/ahoy/click"
      end

      scheme = protocol.present? ? protocol.to_s.delete_suffix("://").delete_suffix(":") : "http"
      return unless ALLOWED_HTTP_SCHEMES.include?(scheme)

      trimmed = host_str.chomp("/")
      return if trimmed.include?("/")
      return if port.present? && trimmed.include?(":")

      port_part = format_external_port(scheme, port)
      return if port_part.nil?

      "#{scheme}://#{trimmed}#{port_part}/ahoy/click"
    end

    def format_external_port(scheme, port)
      return "" if port.blank?

      port_i = port.to_i
      return if port_i <= 0 || port_i > 65_535
      return "" if (scheme == "http" && port_i == 80) || (scheme == "https" && port_i == 443)

      ":#{port_i}"
    end

    def signature(href, token:, campaign:)
      if native_signing_available?
        native = ForemNative.ahoy_signature(AhoyEmail.secret_token, token.to_s, campaign.to_s, href.to_s)
        return native if native
      end

      AhoyEmail::Utils.signature(token: token, campaign: campaign, url: href)
    end

    # Internal links keep their destination and carry the tracking params
    # through to the page, where baseTracking.js posts them to
    # Ahoy::EmailClicksController and strips them from the address bar.
    #
    # "u" is CGI.escaped here and percent-encoded again when Addressable
    # rebuilds the query. That double encoding is deliberate: URLSearchParams
    # decodes once and baseTracking.js calls decodeURIComponent on the result,
    # and the controller verifies the signature against that twice-decoded
    # value.
    def internal_url(uri, href, token:, campaign:)
      if native_signing_available? && href.instance_of?(String) && uri&.host.present?
        native = ForemNative.ahoy_decorate_url(
          href, uri.host, token.to_s, campaign&.to_s, AhoyEmail.secret_token, nil
        )
        return native if native.is_a?(String)
      end

      legacy_internal_url(uri, href, token: token, campaign: campaign)
    end

    def legacy_internal_url(uri, href, token:, campaign:)
      tracking_params = {
        "ahoy_click" => true,
        "t" => token,
        "s" => signature(href, token: token, campaign: campaign),
        "u" => CGI.escape(href),
        "c" => campaign
      }.reject { |_key, value| value.nil? || value.to_s.empty? }

      uri.query_values = (uri.query_values(Array) || []) + tracking_params.to_a

      port_part = uri.port ? ":#{uri.port}" : ""
      url = "#{uri.scheme}://#{uri.host}#{port_part}#{uri.path}"
      url += "?#{uri.query}" if uri.query.present?
      url
    end

    # External links cannot carry our params to a page that would read them, so
    # they redirect through the mounted AhoyEmail engine, which records the
    # click and forwards. That only sets clicked_at -- the other five effects
    # need the recipient to land on this Forem.
    #
    # url_options supplies the host. Note production sets it to
    # protocol + APP_DOMAIN, e.g. "https://dev.to"; ActionDispatch normalizes a
    # host carrying its own scheme, so this still builds a well-formed URL.
    def external_url(href, token:, campaign:, url_options: {})
      if native_signing_available? && href.instance_of?(String) && (base = external_base_url(url_options))
        native = ForemNative.ahoy_decorate_url(
          href, "", token.to_s, campaign&.to_s, AhoyEmail.secret_token, base
        )
        return native if native.is_a?(String)
      end

      legacy_external_url(href, token: token, campaign: campaign, url_options: url_options)
    end

    def legacy_external_url(href, token:, campaign:, url_options: {})
      AhoyEmail::Engine.routes.url_helpers.url_for(
        url_options.merge(
          controller: "ahoy/messages",
          action: "click",
          t: token,
          c: campaign,
          u: href,
          s: signature(href, token: token, campaign: campaign),
        ),
      )
    end
  end
end
