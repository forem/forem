Rails.application.reloader.to_prepare do
  Dir.glob(Rails.root.join("lib/rack/attack/*.rb")).each do |filename|
    require_dependency filename
  end
end

Rack::Attack.throttled_response_retry_after_header = true

module Rack
  class Attack
    throttle("search_throttle", limit: 5, period: 1) do |request|
      if request.path.starts_with?("/search/")
        track_and_return_ip(request)
      end
    end

    throttle("api_throttle", limit: 3, period: 1) do |request|
      if request.path.starts_with?("/api/") && request.get?
        track_and_return_ip(request)
      end
    end

    throttle("api_write_throttle", limit: 1, period: 1) do |request|
      if request.path.starts_with?("/api/") && (request.put? || request.post? || request.delete?)
        Honeycomb.add_field("user_api_key", request.env["HTTP_API_KEY"])
        ip_address = track_and_return_ip(request)
        if request.env["HTTP_API_KEY"].present?
          "#{ip_address}-#{request.env['HTTP_API_KEY']}"
        elsif ip_address.present?
          ip_address
        end
      end
    end

    throttle("site_hits", limit: 40, period: 2) do |request|
      track_and_return_ip(request)
    end

    throttle("tag_throttle", limit: 2, period: 1) do |request|
      if tag_request?(request)
        track_and_return_ip(request)
      end
    end

    def self.track_and_return_ip(req)
      ip_address = if ApplicationConfig["FASTLY_API_KEY"].present?
                     req.env["HTTP_FASTLY_CLIENT_IP"]
                   else
                     req.remote_ip
                   end
      return if ip_address.blank?

      Honeycomb.add_field("fastly_client_ip", req.env["HTTP_FASTLY_CLIENT_IP"])
      Honeycomb.add_field("remote_ip", req.remote_ip)
      ip_address.to_s
    end

    def self.tag_request?(request)
      request.path.include?("/t/")
    end
  end
end
