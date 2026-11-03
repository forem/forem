# In general this service should be considered deprecated, as it duplicates
# infrastructure management that is better left to the Fastly Terraform
# provider. It solely exists to support the not-yet-Terraformed DEV.to
# deployment, and should be removed whenever that instance has been migrated
# to Terraform control (and, presumably, the relevant bits of Terraform open-
# sourced and documented to replace this).
#
# As such, if VCL snippets are added to the snippets directory, a Forem employee
# should replicate them in the appropriate infrastructure repository and roll
# them out to other non-DEV Forems.

module FastlyConfig
  class Snippets < Base
    FASTLY_FILES = Rails.root.join("config/fastly/snippets/*.vcl").freeze
    TABLE_LOOKUP_REGEX = /table\.lookup\(\s*([a-zA-Z0-9_]+)\s*,\s*"[^"]*"\s*,\s*("[^"]*")\s*\)/

    private

    def file_updated?(filename)
      snippet_name = File.basename(filename, ".vcl").humanize
      snippet = find_snippet(fastly, active_version, snippet_name)

      return true if snippet.nil?

      snippet_content(filename) != snippet.content
    end

    def upsert_config(new_version, filename)
      snippet_name = File.basename(filename, ".vcl").humanize
      snippet = find_snippet(fastly, new_version, snippet_name)
      new_snippet_content = snippet_content(filename)

      if snippet
        snippet.content = new_snippet_content
        snippet.save!
        log_to_datadog("update", snippet, new_version)
      else
        snippet_options = {
          content: new_snippet_content,
          dynamic: 0,
          name: snippet_name,
          service_id: ApplicationConfig["FASTLY_SERVICE_ID"],
          type: "init",
          version: new_version.number
        }

        snippet = fastly.create(Fastly::Snippet, snippet_options)
        log_to_datadog("create", snippet, new_version)
      end

      true
    end

    def snippet_content(filename)
      File.read(filename).gsub(TABLE_LOOKUP_REGEX) do |match|
        dictionary_name = Regexp.last_match(1)
        default_value = Regexp.last_match(2)
        dictionary_exists?(dictionary_name) ? match : default_value
      end
    end

    def dictionary_exists?(dictionary_name)
      @dictionary_exists ||= {}
      return @dictionary_exists[dictionary_name] if @dictionary_exists.key?(dictionary_name)

      @dictionary_exists[dictionary_name] = !find_dictionary(fastly, active_version, dictionary_name).nil?
    end

    def find_dictionary(fastly, version, dictionary_name)
      fastly.get_dictionary(ApplicationConfig["FASTLY_SERVICE_ID"], version.number, dictionary_name)
    rescue Fastly::Error => e
      error_message = JSON.parse(e.message)
      raise e unless error_message["msg"] == "Record not found"

      nil
    end

    def find_snippet(fastly, new_version, snippet_name)
      fastly.get_snippet(ApplicationConfig["FASTLY_SERVICE_ID"], new_version.number, snippet_name)
    rescue Fastly::Error => e
      error_message = JSON.parse(e.message)
      raise e unless error_message["msg"] == "Record not found"

      nil
    end

    def log_to_datadog(update_type, snippet, new_version)
      tags = [
        "snippet_update_type:#{update_type}",
        "snippet_name:#{snippet.name}",
        "new_version:#{new_version.number}",
      ]

      ForemStatsClient.increment("fastly.snippets", tags: tags)
    end
  end
end
