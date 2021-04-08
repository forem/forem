class PushNotificationTarget < ApplicationRecord
  resourcify

  FOREM_BUNDLE = "com.forem.app".freeze
  SUPPORTED_PLATFORMS = [Device::ANDROID, Device::IOS].freeze
  FOREM_APP_PLATFORMS = [Device::IOS].freeze

  validates :app_bundle, presence: true
  validates :platform, presence: true

  # Clear Redis-backed model to ensure it will be recreated with updated values
  after_update :clear_rpush_app

  def forem_app?
    app_bundle == FOREM_BUNDLE
  end

  def active?
    # TRUE if it's marked as `active` in the DB && it has credentials available
    active && auth_credentials?
  end

  def auth_credentials?
    auth_credentials.present?
  end

  def auth_credentials
    if app_bundle == FOREM_BUNDLE && platform == Device::IOS
      ApplicationConfig["RPUSH_IOS_PEM"]
    else
      auth_key
    end
  end

  def recreate_ios_app!
    app = Rpush::Apns2::App.new
    app.name = app_bundle
    app.certificate = auth_credentials.to_s.gsub("\\n", "\n")
    app.environment = Rails.env.production? ? "production" : "development"
    app.password = ""
    app.bundle_id = app_bundle
    app.connections = 1
    app.save!
    app
  end

  def recreate_android_app!
    app = Rpush::Gcm::App.new
    app.name = app_bundle
    app.auth_key = auth_credentials.to_s
    app.connections = 1
    app.save!
    app
  end

  def self.fetch_by(app_bundle:, platform:)
    # This guard clause handles the Forem app special case
    return forem_app_target(platform: platform) if app_bundle == FOREM_BUNDLE

    # All other PushNotificationTarget are simply fetched as usual
    PushNotificationTarget.find_by(app_bundle: app_bundle, platform: platform)
  end

  def self.all_targets
    forem_app_platforms = PushNotificationTarget.where(app_bundle: FOREM_BUNDLE).pluck(:platform)
    (FOREM_APP_PLATFORMS - forem_app_platforms).each do |platform|
      # Re-create the supported Forem apps if they're missing
      PushNotificationTarget.create(app_bundle: FOREM_BUNDLE, platform: platform, active: true)
    end

    PushNotificationTarget.all
  end

  def self.forem_app_target(platform:)
    target = PushNotificationTarget.find_by(app_bundle: FOREM_BUNDLE, platform: platform)
    target || PushNotificationTarget.create(app_bundle: FOREM_BUNDLE, platform: platform, active: true)
  end

  # [@forem/backend] `.where().first` is necessary because we use Redis data storage
  # https://github.com/rpush/rpush/wiki/Using-Redis#find_by_name-cannot-be-used-in-rpush-redis
  # rubocop:disable Rails/FindBy
  def self.rpush_app(app_bundle:, platform:)
    target = PushNotificationTarget.fetch_by(app_bundle: app_bundle, platform: platform)

    case target&.platform
    when Device::IOS
      ios_app = Rpush::Apns2::App.where(name: app_bundle).first
      ios_app || target.recreate_ios_app!
    when Device::ANDROID
      android_app = Rpush::Gcm::App.where(name: app_bundle).first
      android_app || target.recreate_android_app!
    end
  end
  # rubocop:enable Rails/FindBy

  private

  # [@forem/backend] `.where().first` is necessary because we use Redis data storage
  # https://github.com/rpush/rpush/wiki/Using-Redis#find_by_name-cannot-be-used-in-rpush-redis
  # rubocop:disable Rails/FindBy
  def clear_rpush_app
    case platform_was
    when Device::IOS
      Rpush::Apns2::App.where(name: app_bundle_was).first&.destroy
    when Device::ANDROID
      Rpush::Gcm::App.where(name: app_bundle_was).first&.destroy
    end

    # This avoids `destroy` method unexpectedly return true/false in callback
    true
  end
  # rubocop:enable Rails/FindBy
end
