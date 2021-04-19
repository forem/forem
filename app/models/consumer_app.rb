class ConsumerApp < ApplicationRecord
  resourcify

  FOREM_BUNDLE = "com.forem.app".freeze
  SUPPORTED_PLATFORMS = [Device::ANDROID, Device::IOS].freeze
  FOREM_APP_PLATFORMS = [Device::IOS].freeze

  validates :app_bundle, presence: true
  validates :platform, presence: true

  has_many :devices, dependent: :destroy

  # Clear Redis-backed model to ensure it will be recreated with updated values
  after_update :clear_rpush_app

  def forem_app?
    app_bundle == FOREM_BUNDLE
  end

  def creator_app?
    app_bundle != FOREM_BUNDLE
  end

  # When an error is raised during an attempt to deliver PNs we should catch
  # them, mark the app as active=false and the error logged into `last_error`
  # If the app is marked as active and credentials are available it's likely
  # the ConsumerApp is operational.
  def operational?
    active && auth_credentials.present?
  end

  # The Forem apps will get their credentials from an ENV variable, whereas
  # custom PN targets will get their credentials from the auth_key stored in
  # the DB (configured by the Forem creator).
  def auth_credentials
    if forem_app? && FOREM_APP_PLATFORMS.include?(platform)
      ApplicationConfig["RPUSH_IOS_PEM"]
    else
      auth_key
    end
  end

  private

  # [@forem/backend] Rpush models are Redis-backed so certain ActiveRecord
  # queries aren't available. For more information:
  # https://github.com/rpush/rpush/wiki/Using-Redis#find_by_name-cannot-be-used-in-rpush-redis
  def clear_rpush_app
    case platform_was
    when Device::IOS
      Rpush::Apns2::App.where(name: app_bundle_was).to_a.sample&.destroy
    when Device::ANDROID
      Rpush::Gcm::App.where(name: app_bundle_was).to_a.sample&.destroy
    end

    # This avoids `destroy` method unexpectedly return true/false in callback
    true
  end
end
