module ConsumerApps
  class FindOrCreateAllQuery
    def self.call
      forem_bundle = ConsumerApp::FOREM_BUNDLE
      existing_platforms = ConsumerApp.where(app_bundle: forem_bundle).pluck(:platform)
      (ConsumerApp::FOREM_APP_PLATFORMS - existing_platforms).each do |platform|
        # Re-create the supported Forem apps if they're missing
        ConsumerApp.create!(app_bundle: forem_bundle,
                            platform: platform,
                            team_id: ConsumerApp::FOREM_TEAM_ID)
      rescue StandardError => e
        error_tags = [
          "error:#{e.message}",
          "app_bundle:#{forem_bundle}",
          "platform:#{platform}",
        ]
        ForemStatsClient.increment("consumer_apps.create", tags: error_tags)
      end

      ConsumerApp.limit(50)
    end
  end
end
