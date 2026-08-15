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
  # Only internal links are handled here. External links go through the mounted
  # AhoyEmail engine's redirect, whose URL generation differs per caller, so the
  # initializer keeps building those itself.
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
  end
end
