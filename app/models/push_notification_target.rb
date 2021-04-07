class PushNotificationTarget < ApplicationRecord
  FOREM_BUNDLE = "com.forem.app".freeze
  SUPPORTED_FOREM_APP_PLATFORMS = [Device::IOS].freeze

  def enabled?
    if app_bundle == FOREM_BUNDLE && platform == Device::IOS
      ApplicationConfig["RPUSH_IOS_PEM"].present?
    else
      enabled
    end
  end

  def forem_app?
    app_bundle == FOREM_BUNDLE
  end

  def self.fetch_by(app_bundle:, platform:)
    # This guard clause handles the Forem app special case
    return forem_app_target(platform: platform) if app_bundle == FOREM_BUNDLE

    # All other PushNotificationTarget are simply fetched directly
    PushNotificationTarget.find_by(app_bundle: app_bundle, platform: platform)
  end

  def self.all_targets
    forem_app_platforms = PushNotificationTarget.where(app_bundle: FOREM_BUNDLE).pluck(:platform)
    (SUPPORTED_FOREM_APP_PLATFORMS - forem_app_platforms).each do |platform|
      # Fetching the missing platforms will re-create them if they don't exist
      PushNotificationTarget.forem_app(platform: platform)
    end

    PushNotificationTarget.all
  end

  def self.forem_app(platform:)
    target = PushNotificationTarget.find_by(app_bundle: FOREM_BUNDLE, platform: platform)
    target || PushNotificationTarget.create(app_bundle: FOREM_BUNDLE, platform: platform, enabled: true)
  end
end
