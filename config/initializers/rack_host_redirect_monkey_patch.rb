require "rack/host_redirect"
require "addressable/uri"

module RackHostRedirectSafeUriUpdate
  private

  # `rack-host-redirect` 1.3.0 calls `URI(request.url)` inside `#update_url`.
  # When a request arrives directly at `HEROKU_APP_URL` (e.g. via CDN pull zones or
  # bots) with unencoded characters in the path or query string (such as `[` or `]`
  # in `/assets/[name]-[hash].js` or markdown fragments), Ruby's strict RFC 3986
  # `URI.parse` raises an unhandled `URI::InvalidURIError` before reaching routing.
  #
  # Fall back to `Addressable::URI.parse(url).normalize` so the URL is safely
  # percent-encoded and redirected with a 301 instead of raising a 500 error.
  def update_url(url, opts)
    super
  rescue URI::InvalidURIError
    begin
      uri = Addressable::URI.parse(url).normalize
      opts.each do |k, v|
        uri.public_send(:"#{k}=", v)
      end
      uri.to_s
    rescue Addressable::URI::InvalidURIError, ArgumentError
      scheme = url.to_s.start_with?("https://") ? "https" : "http"
      "#{scheme}://#{opts[:host]}/"
    end
  end
end

Rack::HostRedirect.prepend(RackHostRedirectSafeUriUpdate)
