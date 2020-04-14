module FastlyVCL
  # Handles updates to our VCL snippet on Fastly that whitelists params
  class WhitelistedParams
    VCL_DELIMITER_START = "^(".freeze
    VCL_DELIMITER_END = ")$".freeze
    SNIPPET_NAME = "Whitelist certain querystring parameters".freeze
    FILE_PARAMS = YAML.load_file("config/fastly/whitelisted_params.yml").sort.freeze

    class << self
      def update
        fastly = Fastly.new(api_key: ApplicationConfig["FASTLY_API_KEY"])
        service = fastly.get_service(ApplicationConfig["FASTLY_SERVICE_ID"])
        latest_version = service.version

        snippet = fastly.get_snippet(ApplicationConfig["FASTLY_SERVICE_ID"],
                                     latest_version.number,
                                     SNIPPET_NAME)

        unless params_outdated?(snippet.content)
          Rails.logger.info("No Fastly VCL updates needed for version #{latest_version.number}.")
          return
        end

        new_version = latest_version.clone
        new_snippet = fastly.get_snippet(ApplicationConfig["FASTLY_SERVICE_ID"],
                                         new_version.number,
                                         SNIPPET_NAME)
        new_snippet.content = build_content(FILE_PARAMS, new_snippet.content)
        new_snippet.save!

        new_version.activate!
      end

      private

      def params_to_array(snippet_content)
        snippet_suffix = snippet_content.split(VCL_DELIMITER_START).last
        fastly_params = snippet_suffix.split(VCL_DELIMITER_END).first

        fastly_params.split("|").sort
      end

      def build_content(new_params, snippet_content)
        new_params = new_params.join("|")
        snippet_prefix = snippet_content.split(VCL_DELIMITER_START).first
        snippet_suffix = snippet_content.split(VCL_DELIMITER_END).last

        snippet_prefix + VCL_DELIMITER_START + new_params + VCL_DELIMITER_END + snippet_suffix
      end

      def params_outdated?(snippet_content)
        current_params = params_to_array(snippet_content)

        current_params != FILE_PARAMS
      end
    end
  end
end
