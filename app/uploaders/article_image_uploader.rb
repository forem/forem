require "ipaddr"
require "net/http"

class ArticleImageUploader < BaseUploader
  MAX_REDIRECT_HOPS = 3
  OPEN_TIMEOUT = 10
  READ_TIMEOUT = 15

  # Strips markdown image title suffixes and angle brackets, returning the URL
  # only when it is a valid HTTP(S) URI whose host resolves to a public IP.
  def self.normalize_source_url(raw_url)
    return if raw_url.blank?

    candidate = raw_url.to_s.strip.split(/\s+/, 2).first.to_s.delete_prefix("<").delete_suffix(">")
    return if candidate.blank?

    uri = URI.parse(candidate)
    return unless uri.is_a?(URI::HTTP) && uri.host.present?
    return unless resolve_public_ip(uri.host)

    candidate
  rescue URI::InvalidURIError
    nil
  end

  # Normalizes a list of raw candidate image URLs and filters out blank,
  # invalid, private-host, or already-stored S3 bucket URLs.
  def self.normalize_external_image_urls(urls, bucket = ApplicationConfig["AWS_BUCKET_NAME"])
    return [] if bucket.blank?

    stored_image_url = "https://#{bucket}.s3.amazonaws.com"
    bucket_host_pattern = /\A#{Regexp.escape(bucket)}\.s3(?:\.[a-z0-9-]+)?\.amazonaws\.com\z/i
    Array(urls).filter_map do |raw_url|
      next if raw_url.to_s.include?(stored_image_url)

      normalized = normalize_source_url(raw_url)
      next unless normalized

      host = URI.parse(normalized).host
      normalized unless host&.match?(bucket_host_pattern)
    end.uniq
  end

  # Resolves hostname and returns the first public IP address if and only if
  # all resolved addresses are public (non-private, non-loopback, non-link-local).
  def self.resolve_public_ip(hostname)
    return if hostname.blank?

    host = hostname.delete_prefix("[").delete_suffix("]")
    return if %w[localhost 127.0.0.1 ::1].include?(host.downcase)

    begin
      ip = IPAddr.new(host)
      return UnifiedEmbed::Tag.blocked_ip?(ip) ? nil : ip.to_s
    rescue IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
      # Not a bare IP literal; resolve via DNS below.
    end

    addrs = Addrinfo.getaddrinfo(host, nil, nil, :STREAM)
    return if addrs.empty?

    resolved_ips = addrs.map { |addr| IPAddr.new(addr.ip_address) }
    return if resolved_ips.any? { |ip| UnifiedEmbed::Tag.blocked_ip?(ip) }

    resolved_ips.first.to_s
  rescue SocketError, IPAddr::InvalidAddressError, IPAddr::AddressFamilyError
    nil
  end

  def store_dir
    "uploads/articles/"
  end

  def filename
    "#{Array.new(20) { rand(36).to_s(36) }.join}.#{file.extension}" if file.present?
  end

  # Downloads a remote image from a validated public HTTP(S) URL into a
  # binary tempfile, stores it via CarrierWave, and returns the stored URL.
  def upload_from_url(url)
    body, final_uri = fetch_remote_image(url)
    return unless body && final_uri

    temp_file = Tempfile.new(["upload", File.extname(final_uri.path)])
    temp_file.binmode
    temp_file.write(body)
    temp_file.rewind

    store!(temp_file)
    self.url
  rescue StandardError => e
    Rails.logger.error "Failed to handle file upload: #{e.message}"
    nil
  ensure
    temp_file&.close!
  end

  private

  # Downloads the remote image after validating that every hop (initial URL and
  # any HTTP redirect targets) resolves to a public IP, binding Net::HTTP#ipaddr
  # to the validated IP on each hop to prevent DNS rebinding.
  def fetch_remote_image(url, hops_remaining: MAX_REDIRECT_HOPS)
    return if hops_remaining.negative?

    normalized_url = self.class.normalize_source_url(url)
    return unless normalized_url

    uri = URI.parse(normalized_url)
    resolved_ip = self.class.resolve_public_ip(uri.host)
    return unless resolved_ip

    response = perform_bound_get(uri, resolved_ip)
    if response.is_a?(Net::HTTPRedirection)
      location = response["location"]
      return if location.blank?

      next_url = URI.join(normalized_url, location).to_s
      return fetch_remote_image(next_url, hops_remaining: hops_remaining - 1)
    end

    [response.body, uri] if response.is_a?(Net::HTTPSuccess)
  end

  # Performs a single non-redirecting HTTP(S) GET bound to resolved_ip.
  def perform_bound_get(uri, resolved_ip)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == "https")
    http.open_timeout = OPEN_TIMEOUT
    http.read_timeout = READ_TIMEOUT
    http.ipaddr = resolved_ip
    http.start { |conn| conn.request(Net::HTTP::Get.new(uri.request_uri)) }
  end
end
