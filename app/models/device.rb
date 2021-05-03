class Device < ApplicationRecord
  # @fdoxyz to remove app_bundle from Device soon
  self.ignored_columns = ["app_bundle"]

  belongs_to :user
  belongs_to :consumer_app

  IOS = "iOS".freeze
  ANDROID = "Android".freeze

  validates :token, uniqueness: { scope: %i[user_id platform consumer_app_id] }
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
    n.device_token = token
    n.app = ConsumerApps::RpushAppQuery.call(
      app_bundle: consumer_app.app_bundle,
      platform: platform,
    )
    n.data = {
      aps: {
        alert: {
          title: SiteConfig.community_name,
          subtitle: title,
          body: body
        },
        'thread-id': SiteConfig.community_name
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
