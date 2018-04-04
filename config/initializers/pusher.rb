require "pusher"

Pusher.app_id = ENV["PUSHER_APP_ID"]
Pusher.key = ENV["PUSHER_KEY"]
Pusher.secret = ENV["PUSHER_SECRET"]
Pusher.cluster = ENV["PUSHER_CLUSTER"]
Pusher.logger = Rails.logger
Pusher.encrypted = true
