module CloudflareSaas
  # Thin wrapper around the Cloudflare custom hostnames API.
  # https://developers.cloudflare.com/api/resources/custom_hostnames/
  class Client
    include HTTParty
    base_uri "https://api.cloudflare.com/client/v4"
    format :json
    default_timeout 10

    class Error < StandardError
      attr_reader :status

      def initialize(message = nil, status: nil)
        super(message)
        @status = status
      end

      # A 4xx response means Cloudflare rejected the request itself, so retrying
      # the same request will not succeed.
      def client_error?
        status.to_i.between?(400, 499)
      end
    end

    MIN_TLS_VERSION = "1.2".freeze

    # Creates a custom hostname with a Cloudflare-issued DV certificate validated
    # over HTTP. Once the hostname CNAMEs to the fallback origin, Cloudflare answers
    # the validation itself, so the organization only has to add one DNS record.
    #
    # If the hostname already exists in the zone (e.g. it was added by hand or left
    # over from an earlier attempt), the existing record is returned instead.
    #
    # @return [Hash] the custom hostname record
    def self.create_custom_hostname(hostname)
      payload = {
        hostname: hostname,
        ssl: {
          method: "http",
          type: "dv",
          settings: { min_tls_version: MIN_TLS_VERSION }
        }
      }

      response = post("#{zone_path}/custom_hostnames", headers: request_headers, body: payload.to_json)
      return parse_result(response) if response.success?

      existing = find_custom_hostname(hostname)
      return existing if existing

      raise_error(response)
    end

    # @return [Hash, nil] the custom hostname record, or nil if it no longer exists
    def self.get_custom_hostname(id)
      response = get("#{zone_path}/custom_hostnames/#{id}", headers: request_headers)
      return if response.code == 404

      raise_error(response) unless response.success?

      parse_result(response)
    end

    # @return [Hash, nil] the custom hostname record matching the hostname exactly
    def self.find_custom_hostname(hostname)
      response = get("#{zone_path}/custom_hostnames", headers: request_headers, query: { hostname: hostname })
      raise_error(response) unless response.success?

      Array(parse_result(response)).detect { |record| record["hostname"].to_s.casecmp?(hostname.to_s) }
    end

    # Deleting a hostname that no longer exists is treated as success.
    def self.delete_custom_hostname(id)
      response = delete("#{zone_path}/custom_hostnames/#{id}", headers: request_headers)
      return true if response.success? || response.code == 404

      raise_error(response)
    end

    def self.zone_path
      "/zones/#{ApplicationConfig['CLOUDFLARE_SAAS_ZONE_ID']}"
    end

    def self.request_headers
      {
        "Authorization" => "Bearer #{ApplicationConfig['CLOUDFLARE_SAAS_API_TOKEN']}",
        "Content-Type" => "application/json",
        "Accept" => "application/json"
      }
    end

    def self.parse_result(response)
      parsed = response.parsed_response
      parsed = JSON.parse(response.body) if parsed.is_a?(String)
      parsed["result"]
    rescue JSON::ParserError, TypeError, NoMethodError => e
      Rails.logger.error("[CloudflareSaas::Client] Unable to parse response: #{e.message}")
      raise Error, "Cloudflare API Error: Unable to parse response"
    end

    def self.raise_error(response)
      message = begin
        parsed = response.parsed_response
        parsed = JSON.parse(response.body) if parsed.is_a?(String)
        parsed&.dig("errors", 0, "message")
      rescue StandardError
        nil
      end
      message ||= response.message
      Rails.logger.error("[CloudflareSaas::Client] HTTP #{response.code} - #{message}")
      raise Error.new("Cloudflare API Error: #{message}", status: response.code)
    end

    private_class_method :zone_path, :request_headers, :parse_result, :raise_error
  end
end
