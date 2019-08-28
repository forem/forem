require "pusher"
require "pusher/push_notifications"

Pusher.app_id = ApplicationConfig["PUSHER_APP_ID"]
Pusher.key = ApplicationConfig["PUSHER_KEY"]
Pusher.secret = ApplicationConfig["PUSHER_SECRET"]
Pusher.cluster = ApplicationConfig["PUSHER_CLUSTER"]
Pusher.logger = Rails.logger
Pusher.encrypted = true

Pusher::PushNotifications.configure do |config|
  config.instance_id = ApplicationConfig["PUSHER_BEAMS_ID"]
  config.secret_key = ApplicationConfig["PUSHER_BEAMS_KEY"]
end
