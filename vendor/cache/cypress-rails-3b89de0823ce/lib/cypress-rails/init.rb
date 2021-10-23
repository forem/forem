module CypressRails
  class Init
    DEFAULT_CONFIG = {
      "screenshotsFolder" => "tmp/cypress_screenshots",
      "videosFolder" => "tmp/cypress_videos",
      "trashAssetsBeforeRuns" => false
    }

    def call(dir = Dir.pwd)
      config_path = File.join(dir, "cypress.json")
      json = JSON.pretty_generate(determine_new_config(config_path))
      File.write(config_path, json)
      puts "Cypress config (re)initialized in #{config_path}"
    end

    private

    def determine_new_config(config_path)
      if File.exist?(config_path)
        merge_existing_with_defaults(config_path)
      else
        DEFAULT_CONFIG
      end
    end

    def merge_existing_with_defaults(json_path)
      JSON.parse(File.read(json_path)).merge(DEFAULT_CONFIG).sort.to_h
    end
  end
end
