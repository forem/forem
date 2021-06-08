class ConsumerApp < ApplicationRecord
  resourcify

  FOREM_BUNDLE = "com.forem.app".freeze
  FOREM_APP_PLATFORMS = %w[ios].freeze

  enum platform: { android: Device::ANDROID, ios: Device::IOS }

  validates :app_bundle, presence: true, uniqueness: { scope: :platform }
  validates :platform, inclusion: { in: platforms.keys }

  has_many :devices, dependent: :destroy

  # Clear Redis-backed model to ensure it will be recreated with updated values
  after_update :clear_rpush_app

  def forem_app?
    app_bundle == FOREM_BUNDLE && FOREM_APP_PLATFORMS.include?(platform)
  end

  def creator_app?
    !forem_app?
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
    if forem_app?
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
    case ConsumerApp.platforms[platform_was]
    when Device::IOS
      Rpush::Apns2::App.where(name: app_bundle_was).first&.destroy
    when Device::ANDROID
      Rpush::Gcm::App.where(name: app_bundle_was).first&.destroy
    end

    # This prevents the `destroy` method to return true or false in a callback
    true
  end
  # rubocop:enable Rails/FindBy
end
