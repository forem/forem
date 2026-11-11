module FastlyConfig
  class Dictionaries < Base
    MANAGED_DICTIONARIES = %w[custom_domain_orgs].freeze

    private

    def get_updated_files
      MANAGED_DICTIONARIES.select { |dictionary_name| file_updated?(dictionary_name) }
    end

    def file_updated?(dictionary_name)
      find_dictionary(fastly, active_version, dictionary_name).nil?
    end

    def upsert_config(new_version, dictionary_name)
      dictionary = find_dictionary(fastly, new_version, dictionary_name)
      return true if dictionary

      dictionary_options = {
        name: dictionary_name,
        service_id: ApplicationConfig["FASTLY_SERVICE_ID"],
        version: new_version.number
      }

      created_dictionary = fastly.create(Fastly::Dictionary, dictionary_options)
      log_to_datadog("create", created_dictionary, new_version)
      true
    end

    def find_dictionary(fastly, version, dictionary_name)
      fastly.get_dictionary(ApplicationConfig["FASTLY_SERVICE_ID"], version.number, dictionary_name)
    rescue Fastly::Error => e
      error_message = JSON.parse(e.message)
      raise e unless error_message["msg"] == "Record not found"

      nil
    end

    def log_to_datadog(update_type, dictionary, new_version)
      tags = [
        "dictionary_update_type:#{update_type}",
        "dictionary_name:#{dictionary.name}",
        "new_version:#{new_version.number}",
      ]

      ForemStatsClient.increment("fastly.dictionaries", tags: tags)
    end
  end
end
