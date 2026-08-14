module FastlyTls
  class Client
    include HTTParty
    base_uri "https://api.fastly.com"
    format :json
    default_timeout 10

    class Error < StandardError; end

    def self.create_subscription(domain)
      payload = {
        data: {
          type: "tls_subscription",
          attributes: {
            certificate_authority: "lets-encrypt"
          },
          relationships: {
            tls_domains: {
              data: [
                {
                  type: "tls_domain",
                  id: domain
                }
              ]
            }
          }
        }
      }

      if tls_configuration_id.present?
        payload[:data][:relationships][:tls_configuration] = {
          data: {
            type: "tls_configuration",
            id: tls_configuration_id
          }
        }
      end

      begin
        response = post("/tls/subscriptions", headers: headers, body: payload.to_json)
        handle_response(response)

        parsed = response.parsed_response
        parsed = JSON.parse(response.body) if parsed.is_a?(String)
        
        subscription_id = parsed.dig("data", "id")
        if subscription_id.blank?
          Rails.logger.error("[FastlyTls::Client] Missing TLS subscription ID in create_subscription response. Body: #{response.body.inspect}")
          raise Error, "Fastly API Error: Missing TLS subscription ID in response"
        end
        subscription_id
      rescue JSON::ParserError, TypeError, NoMethodError => e
        Rails.logger.error("[FastlyTls::Client] ERROR in create_subscription: #{e.message}")
        raise Error, "Fastly API Error: Unable to parse TLS subscription response"
      end
    end

    def self.get_subscription(id)
      begin
        response = get("/tls/subscriptions/#{id}", headers: headers)
        handle_response(response, allow_not_found: true)
        return nil if response.code == 404

        parsed = response.parsed_response
        parsed = JSON.parse(response.body) if parsed.is_a?(String)
        parsed.dig("data")
      rescue JSON::ParserError, TypeError, NoMethodError => e
        Rails.logger.error("[FastlyTls::Client] ERROR in get_subscription: #{e.message}")
        raise Error, "Fastly API Error: Unable to parse TLS subscription response"
      end
    end

    def self.delete_subscription(id)
      begin
        response = delete("/tls/subscriptions/#{id}", headers: headers)
        handle_response(response, allow_not_found: true)
        true
      rescue JSON::ParserError => e
        Rails.logger.error("[FastlyTls::Client] ERROR in delete_subscription: #{e.message}")
        raise Error, "Fastly API Error: Unable to parse TLS subscription response"
      end
    end

    def self.headers
      {
        "Fastly-Key" => ApplicationConfig["FASTLY_API_KEY"],
        "Accept" => "application/vnd.api+json",
        "Content-Type" => "application/vnd.api+json",
        "User-Agent" => "#{Settings::Community.community_name} (#{URL.url})"
      }
    end

    def self.tls_configuration_id
      ApplicationConfig["FASTLY_PLATFORM_TLS_CONFIGURATION_ID"]
    end

    def self.handle_response(response, allow_not_found: false)
      return if response.success?
      return if allow_not_found && response.code == 404

      begin
        parsed = response.parsed_response
        parsed = JSON.parse(response.body) if parsed.is_a?(String)
      rescue StandardError
        parsed = nil
      end
      error_message = parsed&.dig("errors", 0, "detail") || response.message
      Rails.logger.error("[FastlyTls::Client] HTTP #{response.code} - #{error_message}")
      raise Error, "Fastly API Error: #{error_message}"
    end
  end
end
