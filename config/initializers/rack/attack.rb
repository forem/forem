Rack::Attack.throttled_response_retry_after_header = true

class Rack::Attack
  throttle("search_throttle", limit: 5, period: 1) do |request|
    if request.path.starts_with?("/search/") && request.env["HTTP_FASTLY_CLIENT_IP"].present?
      Honeycomb.add_field("fastly_client_ip", request.env["HTTP_FASTLY_CLIENT_IP"])
      request.env["HTTP_FASTLY_CLIENT_IP"].to_s
    end
  end

  throttle("api_throttle", limit: 3, period: 1) do |request|
    if request.path.starts_with?("/api/") && request.get? && request.env["HTTP_FASTLY_CLIENT_IP"].present?
      Honeycomb.add_field("fastly_client_ip", request.env["HTTP_FASTLY_CLIENT_IP"])
      request.env["HTTP_FASTLY_CLIENT_IP"].to_s
    end
  end

  throttle("api_write_throttle", limit: 1, period: 1) do |request|
    if request.path.starts_with?("/api/") && (request.put? || request.post? || request.delete?)
      Honeycomb.add_field("user_api_key", request.env["HTTP_API_KEY"])
      request.env["HTTP_API_KEY"]
    end
  end

  throttle("site_hits", limit: 40, period: 2) do |request|
    if request.env["HTTP_FASTLY_CLIENT_IP"].present?
      Honeycomb.add_field("fastly_client_ip", request.env["HTTP_FASTLY_CLIENT_IP"])
      request.env["HTTP_FASTLY_CLIENT_IP"].to_s
    end
  end

  throttle("message_throttle", limit: 2, period: 1) do |request|
    if request.path.starts_with?("/messages") && request.post? && request.env["HTTP_FASTLY_CLIENT_IP"].present?
      Honeycomb.add_field("fastly_client_ip", request.env["HTTP_FASTLY_CLIENT_IP"])
      request.env["HTTP_FASTLY_CLIENT_IP"].to_s
    end
  end
end
