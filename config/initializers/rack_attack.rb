Rack::Attack.throttled_response_retry_after_header = true

module Rack
  class Attack
    ADMIN_API_CACHE_KEY = "rack_attack_admin_api_keys".freeze
    ADMIN_ROLES = %w[admin super_admin tech_admin].freeze

    # Method that checks API Key from the request and returns true if it
    # belongs to an admin, false otherwise
    def self.admin_api_key?(request)
      api_key = request.env["HTTP_API_KEY"]
      return false if api_key.nil?

      # Admin API Secrets are cached to avoid making DB queries on each request
      admin_keys = Rails.cache.fetch(ADMIN_API_CACHE_KEY, expires_in: 24.hours) do
        ApiSecret.joins(user: :roles)
          .where(roles: { name: ADMIN_ROLES })
          .group("api_secrets.id")
          .pluck(:secret)
      end

      admin_keys.include?(api_key)
    end

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
      api_endpoint = request.path.starts_with?("/api/")
      if api_endpoint && request.get? && !admin_api_key?(request)
        request.track_and_return_ip
      end
    end

    throttle("api_write_throttle", limit: 1, period: 1) do |request|
      api_endpoint = request.path.starts_with?("/api/")
      if api_endpoint && (request.put? || request.post? || request.delete?)
        Honeycomb.add_field("user_api_key", request.env["HTTP_API_KEY"])
        unless admin_api_key?(request)
          ip_address = request.track_and_return_ip
          if request.env["HTTP_API_KEY"].present?
            "#{ip_address}-#{request.env['HTTP_API_KEY']}"
          elsif ip_address.present?
            ip_address
          end
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
