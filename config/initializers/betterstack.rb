# Ship production logs to Better Stack as well as to the existing logger (stdout on Heroku).
# Off unless BETTERSTACK_SOURCE_TOKEN is set, and the logtail gem isn't loaded otherwise.
if Rails.env.production? && ENV["BETTERSTACK_SOURCE_TOKEN"].present?
  require Rails.root.join("lib/betterstack/log_device")

  betterstack_logger = Logtail::Logger.new(
    Betterstack::LogDevice.new(
      ENV.fetch("BETTERSTACK_SOURCE_TOKEN"),
      # Falls back to logtail's default host when unset.
      ingesting_host: ENV["BETTERSTACK_INGESTING_HOST"].presence,
    ),
  )
  betterstack_logger.level = Rails.logger.level

  # Logtail::Logger must not respond to #tagged: BroadcastLogger runs a tagged block once per
  # logger that does, so ActiveJob#perform_now would run every job twice.
  Rails.logger.broadcast_to(betterstack_logger)
end
