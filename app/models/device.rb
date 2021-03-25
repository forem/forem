class Device < ApplicationRecord
  belongs_to :user

  IOS = "iOS".freeze
  ANDROID = "Android".freeze

  validates :token, uniqueness: { scope: %i[user_id platform app_bundle] }
  validates :platform, inclusion: { in: [IOS, ANDROID] }

  def create_notification(title, body, payload)
    case platform
    when IOS
      ios_notification(title, body, payload)
    when ANDROID
      android_notification(title, body, payload)
    end
  end

  private

  def ios_notification(title, body, payload)
    n = Rpush::Apns2::Notification.new
    # [@forem/backend] `.where().first` is necessary because we use Redis data storage
    # https://github.com/rpush/rpush/wiki/Using-Redis#find_by_name-cannot-be-used-in-rpush-redis
    # rubocop:disable Rails/FindBy
    n.app = Rpush::Apns2::App.where(name: app_bundle).first || recreate_ios_app!
    # rubocop:enable Rails/FindBy

    n.device_token = token
    n.data = {
      aps: {
        alert: {
          title: ApplicationConfig["COMMUNITY_NAME"],
          subtitle: title,
          body: body
        },
        'thread-id': ApplicationConfig["COMMUNITY_NAME"]
      },
      data: payload
    }
    n.save!
  end

  def android_notification(title, body, payload)
    n = Rpush::Gcm::Notification.new
    # [@forem/backend] `.where().first` is necessary because we use Redis data storage
    # https://github.com/rpush/rpush/wiki/Using-Redis#find_by_name-cannot-be-used-in-rpush-redis
    # rubocop:disable Rails/FindBy
    n.app = Rpush::Gcm::App.where(name: app_bundle).first || recreate_android_app!
    # rubocop:enable Rails/FindBy

    n.registration_ids = [token]
    n.priority = "high"
    n.content_available = true
    n.notification = { title: title, body: body }
    n.data = { data: payload }
    n.save!
  end

  def recreate_ios_app!
    app = Rpush::Apns2::App.new
    app.name = app_bundle
    sanitized_pem = ApplicationConfig["RPUSH_IOS_PEM"].to_s.gsub("\\n", "\n")
    app.certificate = Base64.decode64(sanitized_pem)
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
    app.auth_key = "..."
    app.connections = 1
    app.save!
    app
  end
end
