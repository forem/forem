Rack::Attack.throttled_response_retry_after_header = true

module Rack
  class Attack
    throttle("search_throttle", limit: 5, period: 1) do |request|
      if request.path.starts_with?("/search/")
        track_and_return_ip(request.env["HTTP_FASTLY_CLIENT_IP"])
      end
    end

    throttle("api_throttle", limit: 3, period: 1) do |request|
      if request.path.starts_with?("/api/") && request.get?
        track_and_return_ip(request.env["HTTP_FASTLY_CLIENT_IP"])
      end
    end

    throttle("api_write_throttle", limit: 1, period: 1) do |request|
      if request.path.starts_with?("/api/") && (request.put? || request.post? || request.delete?)
        Honeycomb.add_field("user_api_key", request.env["HTTP_API_KEY"])
        ip_address = track_and_return_ip(request.env["HTTP_FASTLY_CLIENT_IP"])
        if request.env["HTTP_API_KEY"].present?
          "#{ip_address}-#{request.env['HTTP_API_KEY']}"
        elsif ip_address.present?
          ip_address
        end
      end
    end

    throttle("site_hits", limit: 40, period: 2) do |request|
      track_and_return_ip(request.env["HTTP_FASTLY_CLIENT_IP"])
    end

    throttle("message_tag_throttle", limit: 2, period: 1) do |request|
      if message_or_tag_request(request)
        track_and_return_ip(request.env["HTTP_FASTLY_CLIENT_IP"])
      end
    end

    def self.track_and_return_ip(ip_address)
      return if ip_address.blank?

      Honeycomb.add_field("fastly_client_ip", ip_address)
      ip_address.to_s
    end

    def self.message_or_tag_request(request)
      (request.path.starts_with?("/messages") && request.post?) ||
        request.path.include?("/t/")
    end
  end
end
