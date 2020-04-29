module FastlyConfig
  # Handles updates to our Fastly configurations
  class Update
    FASTLY_OPTIONS = %w[Snippets].freeze

    class << self
      def run(options: FASTLY_OPTIONS)
        validate_options(options)

        fastly = Fastly.new(api_key: ApplicationConfig["FASTLY_API_KEY"])
        service = fastly.get_service(ApplicationConfig["FASTLY_SERVICE_ID"])
        active_version = service.versions.detect(&:active?)
        option_handlers = options.map { |option| "FastlyConfig::#{option}".constantize.new(fastly, active_version) }
        options_updated = option_handlers.any?(&:update_needed?)

        return unless options_updated

        new_version = service.version.clone
        option_handlers.each { |option_handler| option_handler.update(new_version) }
        new_version.activate!
        log_to_datadog(options, new_version)
        Rails.logger.info("Fastly updated to version #{new_version.number}.")
      rescue Fastly::Error => e
        error_msg = JSON.parse(e.message)
        raise e unless unauthorized_error?(error_msg) && Rails.env.development?

        nil
      end

      private

      def log_to_datadog(options, new_version)
        tags = [
          "new_version:#{new_version.number}",
          "options_updated:#{options.join(', ')}",
        ]

        DatadogStatsClient.increment("fastly.update", tags: tags)
      end

      def validate_options(options)
        raise FastlyConfig::Errors::InvalidOptionsFormat, "Options must be an Array of Strings" unless options.is_a? Array

        options.each do |option|
          raise FastlyConfig::Errors::InvalidOption.new(option, FASTLY_OPTIONS) unless FASTLY_OPTIONS.include? option
        end
      end

      def unauthorized_error?(error_msg)
        error_msg["msg"] == "Provided credentials are missing or invalid"
      end
    end
  end
end
