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
    active && auth_credentials.present?
  end

  # The Forem apps will get their credentials from an ENV variable, whereas
  # custom PN targets will get their credentials from the auth_key stored in
  # the DB (configured by the Forem creator).
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
    app.environment = Rails.env
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

  # [@forem/backend] `.where().first` is necessary because we use Redis data storage
  # https://github.com/rpush/rpush/wiki/Using-Redis#find_by_name-cannot-be-used-in-rpush-redis
  # rubocop:disable Rails/FindBy
  def self.rpush_app(app_bundle:, platform:)
    target = PushNotifications::Targets::FetchBy.call(app_bundle: app_bundle, platform: platform)

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
