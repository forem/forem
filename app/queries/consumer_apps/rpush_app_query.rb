module ConsumerApps
  class RpushAppQuery
    def self.call(app_bundle:, platform:)
      new(app_bundle: app_bundle, platform: platform).call
    end

    def initialize(app_bundle:, platform:)
      @app_bundle = app_bundle
      @platform = platform
      @app_name = "#{app_bundle}.#{platform}"

      @consumer_app = ConsumerApps::FindOrCreateByQuery.call(
        app_bundle: @app_bundle,
        platform: @platform,
      )
    end

    def call
      if consumer_app.android?
        android_app = Rpush::Gcm::App.where(name: app_name).first
        return android_app unless stale?(rpush_app: android_app)

        recreate_android_app!
      elsif consumer_app.ios?
        ios_app = Rpush::Apns2::App.where(name: app_name).first
        return ios_app unless stale?(rpush_app: ios_app)

        recreate_ios_app!
      end
    end

    private

    attr_reader :app_bundle, :app_name, :consumer_app, :platform

    # Returns whether the app is stale, which means it needs to be
    # created or recreated if it already exists (credentials changed)
    def stale?(rpush_app:)
      # If the app doesn't exist => stale
      return true if rpush_app.nil?

      # If credentials have changed on either platform => stale (destroy + recreate)
      if consumer_app.android? && rpush_app.auth_key != app_auth_credentials
        rpush_app.destroy
        return true
      elsif consumer_app.ios? && rpush_app.certificate != app_auth_credentials
        rpush_app.destroy
        return true
      end

      # App exists and credentials still match => not stale
      false
    end

    # Fetch the current credentials of the consumer_app
    def app_auth_credentials
      if consumer_app.android?
        consumer_app.auth_credentials.to_s
      elsif consumer_app.ios?
        consumer_app.auth_credentials.to_s.gsub("\\n", "\n")
      end
    end

    def recreate_ios_app!
      # If the ConsumerApp doesn't have credentials there's no need to create it
      return if consumer_app.auth_credentials.blank?

      app = Rpush::Apns2::App.new
      app.name = app_name
      app.certificate = app_auth_credentials
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
      app.name = app_name
      app.auth_key = app_auth_credentials
      app.connections = 1
      app.save!
      app
    end
  end
end
