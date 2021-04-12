module AppIntegrations
  class FetchBy
    def self.call(app_bundle:, platform:)
      new(app_bundle: app_bundle, platform: platform).call
    end

    def initialize(app_bundle:, platform:)
      @app_bundle = app_bundle
      @platform = platform
      @forem_bundle = AppIntegration::FOREM_BUNDLE
    end

    def call
      # This guard clause handles the Forem app special case
      return forem_app_target if @app_bundle == @forem_bundle

      # All other AppIntegration are simply fetched as usual
      AppIntegration.find_by(app_bundle: @app_bundle, platform: @platform)
    end

    private

    def forem_app_target
      target = AppIntegration.find_by(app_bundle: @forem_bundle, platform: @platform)
      target || AppIntegration.create(app_bundle: @forem_bundle, platform: @platform, active: true)
    end
  end
end
