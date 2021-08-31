class Device < ApplicationRecord
  belongs_to :consumer_app
  belongs_to :user

  IOS = "iOS".freeze
  ANDROID = "Android".freeze

  enum platform: { android: ANDROID, ios: IOS }

  validates :platform, inclusion: { in: platforms.keys }
  validates :token, presence: true
  validates :token, uniqueness: { scope: %i[user_id platform consumer_app_id] }

  def create_notification(title, body, payload)
    if android?
      android_notification(title, body, payload)
    elsif ios?
      ios_notification(title, body, payload)
    end
  end

  private

  def ios_notification(title, body, payload)
    n = Rpush::Apns2::Notification.new
    n.device_token = token
    n.app = ConsumerApps::RpushAppQuery.call(
      app_bundle: consumer_app.app_bundle,
      platform: platform,
    )
    n.data = {
      aps: {
        alert: {
          title: Settings::Community.community_name,
          subtitle: title,
          body: body
        },
        "thread-id": Settings::Community.community_name
      },
      data: payload
    }
    n.save!
  end

  def android_notification(title, body, payload)
    n = Rpush::Gcm::Notification.new
    n.app = ConsumerApp.rpush_app(app_bundle: app_bundle, platform: platform)
    n.registration_ids = [token]
    n.priority = "high"
    n.content_available = true
    n.notification = { title: title, body: body }
    n.data = { data: payload }
    n.save!
  end
end
