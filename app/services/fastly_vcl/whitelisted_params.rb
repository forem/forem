module FastlyVCL
  # Handles updates to our VCL snippet on Fastly that whitelists params
  class WhitelistedParams
    VCL_DELIMITER_START = "^(".freeze
    VCL_DELIMITER_END = ")$".freeze
    SNIPPET_NAME = ApplicationConfig["FASTLY_WHITELIST_PARAMS_SNIPPET_NAME"].freeze
    FILE_PARAMS = YAML.load_file("config/fastly/whitelisted_params.yml").freeze

    class << self
      def update
        fastly = Fastly.new(api_key: ApplicationConfig["FASTLY_API_KEY"])
        service = fastly.get_service(ApplicationConfig["FASTLY_SERVICE_ID"])
        latest_version = service.version

        snippet = fastly.get_snippet(ApplicationConfig["FASTLY_SERVICE_ID"],
                                     latest_version.number,
                                     SNIPPET_NAME)

        current_params = params_to_array(snippet.content)

        return unless params_updated?(current_params)

        new_version = latest_version.clone
        new_snippet = fastly.get_snippet(ApplicationConfig["FASTLY_SERVICE_ID"],
                                         new_version.number,
                                         SNIPPET_NAME)
        new_snippet.content = build_content(FILE_PARAMS, new_snippet.content)
        new_snippet.save!

        new_version.activate!
        log_params_diff_to_datadaog(current_params, new_version)
        Rails.logger.info("Fastly updated to version #{new_version.number}.")
      end

      private

      def params_updated?(current_params)
        (current_params - FILE_PARAMS).any? || (FILE_PARAMS - current_params).any?
      end

      def params_to_array(snippet_content)
        snippet_suffix = snippet_content.split(VCL_DELIMITER_START).last
        fastly_params = snippet_suffix.split(VCL_DELIMITER_END).first

        fastly_params.split("|")
      end

      def build_content(new_params, snippet_content)
        new_params = new_params.join("|")
        snippet_prefix = snippet_content.split(VCL_DELIMITER_START).first
        snippet_suffix = snippet_content.split(VCL_DELIMITER_END).last

        "#{snippet_prefix}#{VCL_DELIMITER_START}#{new_params}#{VCL_DELIMITER_END}#{snippet_suffix}"
      end

      def log_params_diff_to_datadaog(current_params, new_version)
        tags = [
          "added_params:#{(FILE_PARAMS - current_params).join(', ')}",
          "removed_params:#{(current_params - FILE_PARAMS).join(', ')}",
          "new_version:#{new_version.number}",
        ]

        DatadogStatsClient.increment("fastly.whitelist", tags: tags)
      end
    end
  end
end
