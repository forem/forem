# Issues GET requests to user-supplied URLs only when every hop resolves to a
# public address.
#
# HTTParty follows redirects on its own, so checking just the first URL is not
# enough: a public host can redirect to an internal one. SafeHttp disables
# HTTParty's redirect handling and re-validates each Location before following it,
# using the same address rules as UnifiedEmbed::Tag and OpenGraph.
#
# Each hop's hostname is resolved once. The request then connects to the address
# that was checked rather than resolving the name again, so a DNS answer that
# changes between the check and the connection cannot redirect the request.
#
# Errors subclass HTTParty::Error so callers that already rescue HTTParty
# failures treat a rejected URL like any other network failure.
class SafeHttp
  MAX_REDIRECTS = 5
  ALLOWED_SCHEMES = %w[http https].freeze

  Error = Class.new(HTTParty::Error)
  BlockedUrlError = Class.new(Error)
  TooManyRedirectsError = Class.new(Error)

  # Connects to the pinned address instead of resolving the hostname again.
  # Net::HTTP keeps using the hostname for the Host header, TLS SNI and
  # certificate verification.
  class PinnedConnectionAdapter < HTTParty::ConnectionAdapter
    def connection
      http = super
      pinned_address = options.dig(:connection_adapter_options, :pinned_address)
      http.ipaddr = pinned_address if pinned_address
      http
    end
  end

  # @param url [String] the URL to fetch
  # @param max_redirects [Integer] how many redirects to follow before giving up
  # @param options [Hash] passed through to HTTParty.get (follow_redirects is always false)
  # @yield [fragment] streamed body fragments, as with HTTParty.get; fragments of
  #   redirect responses are also yielded, so check fragment.code if that matters
  # @return [HTTParty::Response] the final, non-redirect response
  # @raise [BlockedUrlError] when a URL is not http(s) or resolves to a non-public address
  # @raise [TooManyRedirectsError] when more than max_redirects redirects are encountered
  def self.get(url, max_redirects: MAX_REDIRECTS, **options, &block)
    current_url = url.to_s
    # Cookies set by redirect responses in this chain, keyed by the host that set them.
    cookie_jars = {}

    (max_redirects + 1).times do
      uri, address = validate!(current_url)

      response = HTTParty.get(current_url, **request_options(options, address, cookie_jars[uri.hostname]), &block)
      return response unless response.try(:redirection?)

      location = response.headers["location"]
      return response if location.blank?

      store_cookies(cookie_jars, uri.hostname, response)
      current_url = resolve_location(current_url, location)
    end

    raise TooManyRedirectsError, "Too many redirects fetching #{url}"
  end

  # @return [Array(URI::Generic, String)] the parsed URI and the address to connect to
  def self.validate!(url)
    uri = begin
      URI.parse(url)
    rescue URI::Error
      nil
    end

    unless uri && ALLOWED_SCHEMES.include?(uri.scheme) && uri.host.present?
      raise BlockedUrlError, "Blocked non-HTTP URL: #{url}"
    end

    # `hostname` strips the brackets from IPv6 literals so they parse as addresses.
    addresses = resolve_addresses(uri.hostname)
    if addresses.empty? || addresses.any? { |ip| UnifiedEmbed::Tag.blocked_ip?(ip) }
      raise BlockedUrlError, "Blocked request to non-public host: #{uri.hostname}"
    end

    [uri, addresses.first.to_s]
  end
  private_class_method :validate!

  # Returns every address the host resolves to, or an empty array when it cannot be
  # resolved (which validate! treats as blocked).
  def self.resolve_addresses(host)
    return [] if host.blank?

    begin
      return [IPAddr.new(host)]
    rescue IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
      # Not an IP literal; resolve it below.
    end

    Addrinfo.getaddrinfo(host, nil, nil, :STREAM).map { |addr| IPAddr.new(addr.ip_address) }.uniq
  rescue SocketError, IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
    []
  end
  private_class_method :resolve_addresses

  def self.request_options(options, address, cookie_jar)
    request_options = options.merge(
      follow_redirects: false,
      connection_adapter: PinnedConnectionAdapter,
      connection_adapter_options: { pinned_address: address },
    )
    return request_options if cookie_jar.blank?

    headers = (options[:headers] || {}).to_h.dup
    headers["Cookie"] = [headers["Cookie"], cookie_jar.to_cookie_string].compact_blank.join("; ")
    request_options.merge(headers: headers)
  end
  private_class_method :request_options

  # Keeps cookies from a redirect response for later hops to the same host, as
  # HTTParty does when it follows redirects itself.
  def self.store_cookies(cookie_jars, host, response)
    set_cookies = Array(response.headers.get_fields("set-cookie"))
    return if set_cookies.empty?

    jar = cookie_jars[host] ||= HTTParty::CookieHash.new
    set_cookies.each { |cookie| jar.add_cookies(cookie) }
  end
  private_class_method :store_cookies

  def self.resolve_location(current_url, location)
    URI.join(current_url, location).to_s
  rescue URI::Error
    location
  end
  private_class_method :resolve_location
end
