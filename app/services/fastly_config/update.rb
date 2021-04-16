module FastlyConfig
  # Handles updates to our Fastly configurations
  class Update
    FASTLY_CONFIGS = %w[Snippets].freeze

    def self.call
      new.run
    end

    attr_reader :fastly, :service

    def initialize
      @fastly = Fastly.new(api_key: ApplicationConfig["FASTLY_API_KEY"])
      @service = fastly.get_service(ApplicationConfig["FASTLY_SERVICE_ID"])
    end

    def run(configs: FASTLY_CONFIGS)
      validate_configs(configs)

      active_version = get_active_version(service)
      config_handlers = configs.map { |config| "FastlyConfig::#{config}".constantize.new(fastly, active_version) }
      configs_updated = config_handlers.any?(&:update_needed?)

      return unless configs_updated

      new_version = active_version.clone
      config_handlers.each { |config_handler| config_handler.update(new_version) }
      new_version.activate!
      log_to_datadog(configs, new_version)
      Rails.logger.info("Fastly updated to version #{new_version.number}.")
    rescue Fastly::Error => e
      error_msg = JSON.parse(e.message)
      raise e unless unauthorized_error?(error_msg) && Rails.env.development?

      nil
    end

    private

    def get_active_version(service)
      service.versions.reverse_each.detect(&:active?)
    end

    def log_to_datadog(configs, new_version)
      tags = [
        "new_version:#{new_version.number}",
        "configs_updated:#{configs.join(', ')}",
      ]

      ForemStatsClient.increment("fastly.update", tags: tags)
    end

    def validate_configs(configs)
      raise FastlyConfig::Errors::InvalidConfigsFormat unless configs.is_a? Array

      configs.each do |config|
        raise FastlyConfig::Errors::InvalidConfig.new(config, FASTLY_CONFIGS) unless FASTLY_CONFIGS.include? config
      end
    end

    def unauthorized_error?(error_msg)
      error_msg["msg"] == "Provided credentials are missing or invalid"
    end
  end
end
