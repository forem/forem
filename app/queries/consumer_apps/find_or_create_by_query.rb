module ConsumerApps
  class FindOrCreateByQuery
    def self.call(app_bundle:, platform:)
      new(app_bundle: app_bundle, platform: platform).call
    end

    def initialize(app_bundle:, platform:)
      @app_bundle = app_bundle
      @platform = platform
    end

    def call
      # This guard clause handles the Forem app special case
      return forem_app_target if @app_bundle == ConsumerApp::FOREM_BUNDLE

      # All other ConsumerApp are simply fetched as usual
      ConsumerApp.find_by(app_bundle: @app_bundle, platform: @platform)
    end

    private

    def forem_app_target
      ConsumerApp.create_or_find_by(app_bundle: ConsumerApp::FOREM_BUNDLE, platform: @platform)
    end
  end
end
