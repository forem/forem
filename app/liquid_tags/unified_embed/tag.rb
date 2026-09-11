require "net/http"
require "ipaddr"

module UnifiedEmbed
  class Tag < LiquidTagBase
    MAX_REDIRECTION_COUNT = 3
    MINIMAL_ALLOWLIST = [LinkTag].freeze

    # Additional blocked ranges beyond what Ruby's IPAddr#private?, #loopback?,
    # and #link_local? cover. Hoisted to frozen constants to avoid allocating
    # new IPAddr objects on every call to blocked_ip?.
    BLOCKED_UNSPECIFIED_RANGE = IPAddr.new("0.0.0.0/8").freeze        # wildcard / unspecified IPv4
    BLOCKED_CGNAT_RANGE       = IPAddr.new("100.64.0.0/10").freeze    # Carrier-Grade NAT (RFC 6598)
    BLOCKED_IPV4_MAPPED_RANGE = IPAddr.new("::ffff:0:0/96").freeze    # IPv4-mapped IPv6
    BLOCKED_IPV4_COMPAT_RANGE = IPAddr.new("::/96").freeze            # IPv4-compatible IPv6 (deprecated RFC 4291)
    BLOCKED_IPV6_UNSPECIFIED  = IPAddr.new("::/128").freeze           # IPv6 unspecified address (::)
    BLOCKED_IPV6_ULA_RANGE    = IPAddr.new("fc00::/7").freeze         # IPv6 unique-local

    BLOCKED_RANGES = [
      BLOCKED_UNSPECIFIED_RANGE,
      BLOCKED_CGNAT_RANGE,
      BLOCKED_IPV4_MAPPED_RANGE,
      BLOCKED_IPV4_COMPAT_RANGE,
      BLOCKED_IPV6_UNSPECIFIED,
      BLOCKED_IPV6_ULA_RANGE,
    ].freeze

    def self.new(tag_name, input, parse_context)
      stripped_input = ActionController::Base.helpers.strip_tags(input).strip

      # Parse input to check for 'minimal' keyword
      parts = stripped_input.split(/\s+/)
      minimal_mode = parts.include?("minimal")

      # Find the URL (first part that looks like a URL)
      url = parts.find { |part| part.match?(%r{^https?://}) } || parts.first

      handler_before_validation = UnifiedEmbed::Registry.find_handler_for(link: url)

      begin
        validated_link = if handler_before_validation&.dig(:skip_validation)
                           url
                         else
                           validate_link(input: url)
                         end

        # In minimal mode, only use allow-listed embeds, otherwise fall back to OpenGraphTag
        klass = if minimal_mode
                  if handler_before_validation && MINIMAL_ALLOWLIST.include?(handler_before_validation[:klass])
                    handler_before_validation[:klass]
                  else
                    OpenGraphTag
                  end
                else
                  UnifiedEmbed::Registry.find_liquid_tag_for(link: validated_link)
                end

        klass.__send__(:new, tag_name, validated_link, parse_context)
      rescue SocketError, Timeout::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, OpenSSL::SSL::SSLError => e
        Rails.logger.warn("[UnifiedEmbed::Tag] Network/SSL error during validation for '#{url}': #{e.class} - #{e.message}")
        FallbackTag.__send__(:new, tag_name, url, parse_context)
      end
    end

    def self.validate_link(input:, retries: MAX_REDIRECTION_COUNT, method: Net::HTTP::Head)
      uri = URI.parse(input.split.first)
      return input if uri.host == "twitter.com" || uri.host == "x.com" || uri.host == "bsky.app"

      # Prevent SSRF attacks on internal networks
      raise StandardError, I18n.t("liquid_tags.unified_embed.tag.invalid_url") if private_ip?(uri.host)

      # Build HTTP client with correct port and TLS based on scheme
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true if uri.scheme == "https"
      
      # Set security timeouts to prevent hanging requests
      http.open_timeout = 10
      http.read_timeout = 15

      path = uri.path.empty? ? "/" : uri.path
      req = method.new(path + (uri.query ? "?#{uri.query}" : ""))
      req["User-Agent"] = "ForemLinkValidator/1.0 (+#{URL.url}; #{safe_user_agent})"

      response = http.request(req)

      if uri.host == "codepen.io" && response.is_a?(Net::HTTPForbidden)
        response = http.request(req)
      end

      case response
      when Net::HTTPSuccess
        input
      when Net::HTTPUnauthorized, Net::HTTPForbidden
        # Some sites block bots or require auth; consider the URL valid but we won't be able to fetch metadata
        input
      when Net::HTTPRedirection
        raise StandardError, I18n.t("liquid_tags.unified_embed.tag.too_many_redirects") if retries.zero?

        # Resolve relative redirects against the current URI
        location = response["location"]
        begin
          next_url = URI.join(uri, location).to_s
        rescue
          next_url = location
        end

        validate_link(input: next_url, retries: retries - 1)
      when Net::HTTPMethodNotAllowed
        raise StandardError, I18n.t("liquid_tags.unified_embed.tag.invalid_url") if retries.zero?

        validate_link(input: input, retries: retries, method: Net::HTTP::Get)
      when Net::HTTPNotFound
        raise StandardError, I18n.t("liquid_tags.unified_embed.tag.not_found")
      else
        raise StandardError, I18n.t("liquid_tags.unified_embed.tag.invalid_url")
      end
    end

    def self.safe_user_agent(agent = Settings::Community.community_name)
      agent.gsub(/[^-_.()a-zA-Z0-9 ]+/, "-")
    end

    # Prevent SSRF attacks by blocking requests to private IP ranges.
    # Covers:
    #   - Loopback / localhost literals
    #   - RFC 1918 private ranges (10/8, 172.16/12, 192.168/16)
    #   - IPv4 loopback (127/8)
    #   - Link-local (169.254/16, fe80::/10)
    #   - Wildcard / unspecified (0.0.0.0/8)
    #   - IPv4-mapped IPv6 (::ffff:0:0/96) which could otherwise tunnel private IPv4
    #   - IPv6 unique-local (fc00::/7)
    # Resolution failure is treated as DENY: if we cannot confirm a host is public,
    # we must not fetch it.
    def self.private_ip?(hostname)
      # Deny nil, empty, or blank hostnames — if we cannot identify the host,
      # we must not fetch it. This also prevents TypeError from IPAddr.new(nil)
      # and Addrinfo.getaddrinfo(nil, ...) when URI.parse yields a nil host.
      return true if hostname.blank?

      return true if %w[localhost 127.0.0.1 ::1].include?(hostname)

      # First try to parse as IP address directly
      begin
        ip = IPAddr.new(hostname)
        return blocked_ip?(ip)
      rescue IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
        # Not a bare IP literal; fall through to DNS resolution
      end

      # Resolve hostname to IP addresses and check each one.
      # Deny on resolution failure — an unresolvable host's IP range is unknown.
      begin
        Addrinfo.getaddrinfo(hostname, nil, nil, :STREAM).each do |addr|
          ip = IPAddr.new(addr.ip_address)
          return true if blocked_ip?(ip)
        end
        false
      rescue SocketError, IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
        # Cannot resolve: treat as private/blocked to be safe
        true
      end
    end

    # Returns true for any IP address that should be blocked from outbound fetches.
    def self.blocked_ip?(ip)
      return true if ip.loopback? || ip.private? || ip.link_local?

      BLOCKED_RANGES.any? { |range| range.include?(ip) }
    end
  end

  class FallbackTag < LiquidTagBase
    def initialize(_tag_name, url, _parse_context)
      super
      @url = url
    end

    def render(_context)
      parsed = URI.parse(@url) rescue nil
      display_text =
        if parsed&.host
          host = parsed.host.delete_prefix("www.")
          path = parsed.path.to_s.sub(%r{\A/}, "")
          [host, path.presence].compact.join(" / ")
        else
          @url.sub(%r{\Ahttps?://}i, "")
        end

      ApplicationController.render(
        partial: "liquids/open_graph",
        locals: {
          page: OpenStruct.new(main_properties_present?: false),
          url: @url,
          url_domain: display_text,
        },
      )
    end
  end
end

Liquid::Template.register_tag("embed", UnifiedEmbed::Tag)
