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

    def signature(href, token:, campaign:)
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
