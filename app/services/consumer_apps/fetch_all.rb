module AppIntegrations
  class FetchAll
    def self.call
      forem_bundle = AppIntegration::FOREM_BUNDLE
      existing_platforms = AppIntegration.where(app_bundle: forem_bundle).pluck(:platform)
      (AppIntegration::FOREM_APP_PLATFORMS - existing_platforms).each do |platform|
        # Re-create the supported Forem apps if they're missing
        AppIntegration.create(app_bundle: forem_bundle, platform: platform, active: true)
      end

      AppIntegration.all
    end
  end
end
