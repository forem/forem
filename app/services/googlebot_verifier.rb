# frozen_string_literal: true

require "ipaddr"

class GooglebotVerifier
  GOOGLEBOT_IP_RANGES_URL = "https://developers.google.com/static/crawling/ipranges/common-crawlers.json"
  CACHE_KEY = "googlebot_ip_prefixes"
  CACHE_EXPIRY = 24.hours

  def self.googlebot?(ip_string)
    return false if ip_string.blank?

    begin
      client_ip = IPAddr.new(ip_string)
    rescue IPAddr::InvalidAddressError, ArgumentError
      return false
    end

    prefixes = Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_EXPIRY) do
      fetched = fetch_googlebot_prefixes
      fetched.presence
    end

    if prefixes.nil?
      prefixes = fetch_googlebot_prefixes
      if prefixes.present?
        Rails.cache.write(CACHE_KEY, prefixes, expires_in: CACHE_EXPIRY)
      else
        # Cache empty result for a shorter duration (5 minutes) to avoid thrashing Google's servers
        Rails.cache.write(CACHE_KEY, [], expires_in: 5.minutes)
        prefixes = []
      end
    end

    prefixes.any? do |prefix|
      begin
        IPAddr.new(prefix).include?(client_ip)
      rescue IPAddr::InvalidAddressError, ArgumentError
        false
      end
    end
  end

  def self.fetch_googlebot_prefixes
    response = HTTParty.get(GOOGLEBOT_IP_RANGES_URL, timeout: 5)
    return [] unless response.success?

    data = JSON.parse(response.body)
    prefixes = []
    data["prefixes"]&.each do |p|
      prefixes << p["ipv4Prefix"] if p["ipv4Prefix"].present?
      prefixes << p["ipv6Prefix"] if p["ipv6Prefix"].present?
    end
    prefixes
  rescue => e
    Rails.logger.error("Failed to fetch Googlebot IP ranges: #{e.message}")
    []
  end
end
