class Rack::Attack
  throttle("search_throttle", limit: 5, period: 1) do |request|
    if request.path.starts_with?("/search/") && request.env["HTTP_FASTLY_CLIENT_IP"].present?
      request.env["HTTP_FASTLY_CLIENT_IP"].to_s
    end
  end
end
