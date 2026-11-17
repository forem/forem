# Issues GET requests to user-supplied URLs only when every hop resolves to a
# public address.
#
# HTTParty follows redirects on its own, so checking just the first URL is not
# enough: a public host can redirect to an internal one. SafeHttp disables
# HTTParty's redirect handling and re-validates each Location before following it,
# using the same host check as UnifiedEmbed::Tag and OpenGraph.
#
# Errors subclass HTTParty::Error so callers that already rescue HTTParty
# failures treat a rejected URL like any other network failure.
class SafeHttp
  MAX_REDIRECTS = 5
  ALLOWED_SCHEMES = %w[http https].freeze

  Error = Class.new(HTTParty::Error)
  BlockedUrlError = Class.new(Error)
  TooManyRedirectsError = Class.new(Error)

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

    (max_redirects + 1).times do
      validate!(current_url)

      response = HTTParty.get(current_url, **options, follow_redirects: false, &block)
      return response unless response.try(:redirection?)

      location = response.headers["location"]
      return response if location.blank?

      current_url = resolve_location(current_url, location)
    end

    raise TooManyRedirectsError, "Too many redirects fetching #{url}"
  end

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
    if UnifiedEmbed::Tag.private_ip?(uri.hostname)
      raise BlockedUrlError, "Blocked request to non-public host: #{uri.hostname}"
    end

    uri
  end
  private_class_method :validate!

  def self.resolve_location(current_url, location)
    URI.join(current_url, location).to_s
  rescue URI::Error
    location
  end
  private_class_method :resolve_location
end
