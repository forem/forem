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
      if consumer_app.android?
        android_app = Rpush::Gcm::App.where(name: app_bundle).first
        android_app || recreate_android_app!
      elsif consumer_app.ios?
        ios_app = Rpush::Apns2::App.where(name: app_bundle).first
        ios_app || recreate_ios_app!
      end
    end

    private

    attr_reader :app_bundle, :consumer_app

    def recreate_ios_app!
      # If the ConsumerApp doesn't have credentials there's no need to create it
      return if consumer_app.auth_credentials.blank?

      app = Rpush::Apns2::App.new
      app.name = app_bundle
      app.certificate = consumer_app.auth_credentials.to_s.gsub("\\n", "\n")
      app.environment = Rails.env
      app.password = ""
      app.bundle_id = app_bundle
      app.connections = 1
      app.save!
      app
    end

    def recreate_android_app!
      # If the ConsumerApp doesn't have credentials there's no need to create it
      return if consumer_app.auth_credentials.blank?

      app = Rpush::Gcm::App.new
      app.name = app_bundle
      app.auth_key = consumer_app.auth_credentials.to_s
      app.connections = 1
      app.save!
      app
    end
  end
end
