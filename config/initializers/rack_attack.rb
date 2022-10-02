Rack::Attack.throttled_response_retry_after_header = true

module Rack
  class Attack
    class Request < ::Rack::Request
      def track_and_return_ip
        if ApplicationConfig["FASTLY_API_KEY"].present?
          Honeycomb.add_field("fastly_client_ip", env["HTTP_FASTLY_CLIENT_IP"])
          env["HTTP_FASTLY_CLIENT_IP"]
        else
          ActionDispatch::Request.new(env).remote_ip
        end
      end
    end

    throttle("search_throttle", limit: 5, period: 1) do |request|
      if request.path.starts_with?("/search/")
        request.track_and_return_ip
      end
    end

    throttle("api_throttle", limit: 3, period: 1) do |request|
      if request.path.starts_with?("/api/") && request.get?
        request.track_and_return_ip
      end
    end

    throttle("api_write_throttle", limit: 1, period: 1) do |request|
      if request.path.starts_with?("/api/") && (request.put? || request.post? || request.delete?)
        Honeycomb.add_field("user_api_key", request.env["HTTP_API_KEY"])
        ip_address = request.track_and_return_ip
        if request.env["HTTP_API_KEY"].present?
          "#{ip_address}-#{request.env['HTTP_API_KEY']}"
        elsif ip_address.present?
          ip_address
        end
      end
    end

    throttle("site_hits", limit: 40, period: 2, &:track_and_return_ip)

    throttle("tag_throttle", limit: 2, period: 1) do |request|
      if request.path.include?("/t/")
        request.track_and_return_ip
      end
    end
  end
end
