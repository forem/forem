module ConsumerApps
  class AllQuery
    def self.call
      forem_bundle = ConsumerApp::FOREM_BUNDLE
      existing_platforms = ConsumerApp.where(app_bundle: forem_bundle).pluck(:platform)
      (ConsumerApp::FOREM_APP_PLATFORMS - existing_platforms).each do |platform|
        # Re-create the supported Forem apps if they're missing
        ConsumerApp.create(app_bundle: forem_bundle, platform: platform, active: true)
      end

      ConsumerApp.all(super: true)
    end
  end
end
