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
    n.app = PushNotificationTarget.rpush_app(app_bundle: app_bundle, platform: platform)
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
    n.app = PushNotificationTarget.rpush_app(app_bundle: app_bundle, platform: platform)
    n.registration_ids = [token]
    n.priority = "high"
    n.content_available = true
    n.notification = { title: title, body: body }
    n.data = { data: payload }
    n.save!
  end
end
