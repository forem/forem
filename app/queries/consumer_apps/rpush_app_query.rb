module ConsumerApps
  class RpushAppQuery
    def self.call(app_bundle:, platform:)
      new(app_bundle: app_bundle, platform: platform).call
    end

    def initialize(app_bundle:, platform:)
      @app_bundle = app_bundle
      @platform = platform
      @consumer_app = ConsumerApps::FindOrCreateByQuery.call(
        app_bundle: @app_bundle,
        platform: @platform,
      )
    end

    def call
      case @consumer_app&.platform
      when Device::IOS
        ios_app = Rpush::Apns2::App.where(name: @app_bundle).first
        ios_app || recreate_ios_app!
      when Device::ANDROID
        android_app = Rpush::Gcm::App.where(name: @app_bundle).first
        android_app || recreate_android_app!
      end
    end

    private

    def recreate_ios_app!
      app = Rpush::Apns2::App.new
      app.name = @app_bundle
      app.certificate = @consumer_app.auth_credentials.to_s.gsub("\\n", "\n")
      app.environment = Rails.env
      app.password = ""
      app.bundle_id = @app_bundle
      app.connections = 1
      app.save!
      app
    end

    def recreate_android_app!
      app = Rpush::Gcm::App.new
      app.name = @app_bundle
      app.auth_key = @consumer_app.auth_credentials.to_s
      app.connections = 1
      app.save!
      app
    end
  end
end
