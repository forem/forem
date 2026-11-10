module CloudflareTls
  class Client
    include HTTParty
    base_uri "https://api.cloudflare.com/client/v4"
    format :json
    default_timeout 10

    class Error < StandardError; end

    PENDING_STATES = %w[initializing pending pending_validation pending_issuance pending_deployment].freeze
    ISSUED_STATES = %w[active renewing].freeze

    def self.configured?
      ApplicationConfig["CLOUDFLARE_API_TOKEN"].present? && ApplicationConfig["CLOUDFLARE_ZONE_ID"].present?
    end

    def self.create_subscription(domain)
      payload = {
        hostname: domain,
        ssl: {
          method: "http",
          type: "dv"
        }
      }

      response = post("/zones/#{zone_id}/custom_hostnames", headers: headers, body: payload.to_json)
      handle_response(response)

      parsed = parse_body(response)
      subscription_id = parsed.dig("result", "id")
      if subscription_id.blank?
        Rails.logger.error(
          "[CloudflareTls::Client] Missing custom hostname ID in create_subscription response. " \
          "Body: #{response.body.inspect}",
        )
        raise Error, "Cloudflare API Error: Missing custom hostname ID in response"
      end

      subscription_id
    rescue JSON::ParserError, TypeError, NoMethodError => e
      Rails.logger.error("[CloudflareTls::Client] ERROR in create_subscription: #{e.message}")
      raise Error, "Cloudflare API Error: Unable to parse custom hostname response"
    end

    def self.get_subscription(id)
      response = get("/zones/#{zone_id}/custom_hostnames/#{id}", headers: headers)
      handle_response(response, allow_not_found: true)
      return if response.code == 404

      parsed = parse_body(response)
      result = parsed["result"]
      return unless result.is_a?(Hash)

      ssl_status = result.dig("ssl", "status").to_s
      {
        "id" => result["id"],
        "type" => "custom_hostname",
        "attributes" => {
          "state" => normalize_state(ssl_status)
        }
      }
    rescue JSON::ParserError, TypeError, NoMethodError => e
      Rails.logger.error("[CloudflareTls::Client] ERROR in get_subscription: #{e.message}")
      raise Error, "Cloudflare API Error: Unable to parse custom hostname response"
    end

    def self.delete_subscription(id)
      response = delete("/zones/#{zone_id}/custom_hostnames/#{id}", headers: headers)
      handle_response(response, allow_not_found: true)
      true
    rescue JSON::ParserError => e
      Rails.logger.error("[CloudflareTls::Client] ERROR in delete_subscription: #{e.message}")
      raise Error, "Cloudflare API Error: Unable to parse custom hostname response"
    end

    def self.headers
      {
        "Authorization" => "Bearer #{ApplicationConfig['CLOUDFLARE_API_TOKEN']}",
        "Accept" => "application/json",
        "Content-Type" => "application/json",
        "User-Agent" => "#{Settings::Community.community_name} (#{URL.url})"
      }
    end

    def self.zone_id
      ApplicationConfig["CLOUDFLARE_ZONE_ID"]
    end

    def self.normalize_state(ssl_status)
      return "issued" if ISSUED_STATES.include?(ssl_status)
      return "pending" if PENDING_STATES.include?(ssl_status)

      "failed"
    end
    private_class_method :normalize_state

    def self.parse_body(response)
      parsed = response.parsed_response
      parsed = JSON.parse(response.body) if parsed.is_a?(String)
      parsed
    end
    private_class_method :parse_body

    def self.handle_response(response, allow_not_found: false)
      return if response.success?
      return if allow_not_found && response.code == 404

      parsed = begin
        parse_body(response)
      rescue StandardError
        nil
      end
      error_message = parsed&.dig("errors", 0, "message") || response.message
      Rails.logger.error("[CloudflareTls::Client] HTTP #{response.code} - #{error_message}")
      raise Error, "Cloudflare API Error: #{error_message}"
    end
    private_class_method :handle_response
  end
end
