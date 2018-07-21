require "stream_rails"

StreamRails.configure do |config|
  config.api_key     = ApplicationConfig["STREAM_RAILS_KEY"]
  config.api_secret  = ApplicationConfig["STREAM_RAILS_SECRET"]
  config.timeout     = 3 # Optional, defaults to 3
  config.location    = "us-east" # Optional, defaults to 'us-east'
  # If you use custom feed names, e.g.: timeline_flat, timeline_aggregated,
  # use this, otherwise omit:
  # config.news_feeds = { flat: "flat", aggregated: "timeline_aggregated" }
  # Point to the notifications feed group providing the name, omit if you don't
  # have a notifications feed
  config.notification_feed = "notifications"
end
