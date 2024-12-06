module CypressRails
  class Init
    DEFAULT_CONFIG = <<~JS
      const { defineConfig } = require('cypress')

      module.exports = defineConfig({
        // setupNodeEvents can be defined in either
        // the e2e or component configuration
        e2e: {
          setupNodeEvents(on, config) {
            on('before:browser:launch', (browser = {}, launchOptions) => {
              /* ... */
            })
          },
        },
        screenshotsFolder: "tmp/cypress_screenshots",
        videosFolder: "tmp/cypress_videos",
        trashAssetsBeforeRuns: false
      })
    JS

    def call(cypress_dir = Config.new.cypress_dir)
      config_path = File.join(cypress_dir, "cypress.config.js")
      if !File.exist?(config_path)
        File.write(config_path, DEFAULT_CONFIG)
        puts "Cypress config initialized in `#{config_path}'"
      else
        warn "Cypress config already exists in `#{config_path}'. Skipping."
      end
    end
  end
end
