require "pusher/push_notifications"

if ApplicationConfig["PUSHER_APP_ID"].present?
  Pusher.app_id = ApplicationConfig["PUSHER_APP_ID"]
  Pusher.key = ApplicationConfig["PUSHER_KEY"]
  Pusher.secret = ApplicationConfig["PUSHER_SECRET"]
  Pusher.cluster = ApplicationConfig["PUSHER_CLUSTER"]
  Pusher.logger = Rails.logger
  Pusher.encrypted = true

  Pusher::PushNotifications.configure do |config|
    config.instance_id = SiteConfig.push_notifications_identifier
    config.secret_key = SiteConfig.push_notifications_secret
  end
end
