class Rack::Attack
  throttle("search_throttle", limit: 5, period: 1) do |request|
    if request.path.starts_with?("/search/")
      request.ip.to_s
    end
  end
end
