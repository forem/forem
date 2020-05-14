Rack::Attack.throttled_response_retry_after_header = true

class Rack::Attack
  throttle("search_throttle", limit: 5, period: 1) do |request|
    return if request.env["HTTP_FASTLY_CLIENT_IP"].blank?

    if request.path.starts_with?("/search/")
      track_and_return_ip(request.env["HTTP_FASTLY_CLIENT_IP"])
    end
  end

  throttle("api_throttle", limit: 3, period: 1) do |request|
    return if request.env["HTTP_FASTLY_CLIENT_IP"].blank?

    if request.path.starts_with?("/api/") && request.get?
      track_and_return_ip(request.env["HTTP_FASTLY_CLIENT_IP"])
    end
  end

  throttle("api_write_throttle", limit: 1, period: 1) do |request|
    return if request.env["HTTP_FASTLY_CLIENT_IP"].blank?

    if request.path.starts_with?("/api/") && (request.put? || request.post? || request.delete?)
      Honeycomb.add_field("user_api_key", request.env["HTTP_API_KEY"])
      track_and_return_ip(request.env["HTTP_FASTLY_CLIENT_IP"])
    end
  end

  throttle("site_hits", limit: 40, period: 2) do |request|
    return if request.env["HTTP_FASTLY_CLIENT_IP"].blank?

    track_and_return_ip(request.env["HTTP_FASTLY_CLIENT_IP"])
  end

  throttle("message_throttle", limit: 2, period: 1) do |request|
    return if request.env["HTTP_FASTLY_CLIENT_IP"].blank?

    if request.path.starts_with?("/messages") && request.post?
      track_and_return_ip(request.env["HTTP_FASTLY_CLIENT_IP"])
    end
  end

  def self.track_and_return_ip(ip_address)
    Honeycomb.add_field("fastly_client_ip", ip_address)
    ip_address.to_s
  end
end
