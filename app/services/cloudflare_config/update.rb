module CloudflareConfig
  # Syncs `config/cloudflare/worker.js` to Cloudflare Workers via the Cloudflare API,
  # mirroring `FastlyConfig::Update` for `config/fastly/snippets/*.vcl`.
  class Update
    WORKER_SCRIPT_PATH = Rails.root.join("config/cloudflare/worker.js").freeze
    DEFAULT_WORKER_NAME = "forem-edge".freeze
    API_BASE_URL = "https://api.cloudflare.com/client/v4".freeze

    class Error < StandardError; end

    def self.call
      new.run
    end

    attr_reader :account_id, :api_token, :worker_name

    def initialize(
      api_token: ApplicationConfig["CLOUDFLARE_API_TOKEN"],
      account_id: ApplicationConfig["CLOUDFLARE_ACCOUNT_ID"],
      worker_name: ApplicationConfig["CLOUDFLARE_WORKER_NAME"].presence || DEFAULT_WORKER_NAME
    )
      @api_token = api_token
      @account_id = account_id
      @worker_name = worker_name
    end

    def run
      return unless update_needed?

      upload_worker_script!
      log_to_datadog
      Rails.logger.info("Cloudflare Worker #{worker_name} updated.")
      true
    end

    def update_needed?
      remote_script != local_script
    end

    private

    def local_script
      @local_script ||= WORKER_SCRIPT_PATH.read
    end

    def remote_script
      response = HTTParty.get(script_endpoint, headers: auth_headers)
      return if response.code == 404
      raise Error, "Cloudflare API Error (#{response.code}): #{response.body}" unless response.success?

      response.body.to_s
    end

    def upload_worker_script!
      headers = auth_headers.merge("Content-Type" => "application/javascript+module")
      response = HTTParty.put(script_endpoint, headers: headers, body: local_script)
      raise Error, "Cloudflare API Error (#{response.code}): #{response.body}" unless response.success?

      response
    end

    def script_endpoint
      "#{API_BASE_URL}/accounts/#{account_id}/workers/scripts/#{worker_name}"
    end

    def auth_headers
      {
        "Authorization" => "Bearer #{api_token}",
        "User-Agent" => "#{Settings::Community.community_name} (#{URL.url})"
      }
    end

    def log_to_datadog
      ForemStatsClient.increment(
        "cloudflare.update",
        tags: ["worker_name:#{worker_name}", "configs_updated:Worker"],
      )
    end
  end
end
