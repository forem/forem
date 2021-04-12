class AppIntegration < ApplicationRecord
  resourcify

  FOREM_BUNDLE = "com.forem.app".freeze
  SUPPORTED_PLATFORMS = [Device::ANDROID, Device::IOS].freeze
  FOREM_APP_PLATFORMS = [Device::IOS].freeze

  validates :app_bundle, presence: true
  validates :platform, presence: true
  validates :active, inclusion: { in: [true, false] }

  has_many :devices, dependent: :destroy

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
