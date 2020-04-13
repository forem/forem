module FastlyVCL
  # Handles updates to our VCL snippet on Fastly that whitelists params
  class WhitelistedParams
    VCL_REGEX_START = "^(".freeze
    VCL_REGEX_END = ")$".freeze
    FILE_PARAMS = YAML.load_file("config/fastly/whitelisted_params.yml").sort.freeze

    class << self
      def update
        fastly = Fastly.new(api_key: ApplicationConfig["FASTLY_API_KEY"])
        service = fastly.get_service(ApplicationConfig["FASTLY_SERVICE_ID"])
        latest_version = service.version

        snippet = fastly.get_snippet(ApplicationConfig["FASTLY_SERVICE_ID"],
                                     latest_version.number,
                                     "Whitelist certain querystring parameters")

        unless params_outdated?(snippet.content)
          Rails.logger.info("No Fastly VCL updates needed for version #{latest_version.number}.")
          return
        end

        new_version = latest_version.clone
        new_snippet = fastly.get_snippet(ApplicationConfig["FASTLY_SERVICE_ID"],
                                         new_version.number,
                                         "Whitelist certain querystring parameters")
        new_content = build_content(FILE_PARAMS, new_snippet.content)
        new_snippet.content = new_content
        new_snippet.save!

        new_version.activate!
      end

      private

      def params_to_array(snippet_content)
        snippet_suffix = snippet_content.split(VCL_REGEX_START).last
        fastly_params = snippet_suffix.split(VCL_REGEX_END).first

        fastly_params.split("|")
      end

      def build_content(new_params, snippet_content)
        new_params = new_params.join("|")
        snippet_prefix = snippet_content.split(VCL_REGEX_START).first
        snippet_suffix = snippet_content.split(VCL_REGEX_END).last

        snippet_prefix + VCL_REGEX_START + new_params + VCL_REGEX_END + snippet_suffix
      end

      def params_outdated?(snippet_content)
        current_params = params_to_array(snippet_content).sort

        current_params != FILE_PARAMS
      end
    end
  end
end
