if ApplicationConfig["PUSHER_APP_ID"].present?
  Pusher.app_id = ApplicationConfig["PUSHER_APP_ID"]
  Pusher.key = ApplicationConfig["PUSHER_KEY"]
  Pusher.secret = ApplicationConfig["PUSHER_SECRET"]
  Pusher.cluster = ApplicationConfig["PUSHER_CLUSTER"]
  Pusher.logger = Rails.logger
  Pusher.encrypted = true
end
