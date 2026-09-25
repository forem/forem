# Ship production logs to Better Stack as well as to the existing logger (stdout on Heroku).
# Off unless BETTERSTACK_SOURCE_TOKEN is set; logtail-rails is only loaded then (config/application.rb).
if Rails.env.production? && ENV["BETTERSTACK_SOURCE_TOKEN"].present?
  require Rails.root.join("lib/betterstack/log_device")
  require Rails.root.join("lib/betterstack/request_context")

  betterstack_logger = Logtail::Logger.new(
    Betterstack::LogDevice.new(
      ENV.fetch("BETTERSTACK_SOURCE_TOKEN"),
      # Falls back to logtail's default host when unset.
      ingesting_host: ENV["BETTERSTACK_INGESTING_HOST"].presence,
    ),
  )
  # Set BETTERSTACK_LOG_LEVEL=info to also get logtail-rails' per-request events; stdout keeps LOG_LEVEL.
  betterstack_logger.level = ENV["BETTERSTACK_LOG_LEVEL"].presence&.to_sym || Rails.logger.level

  # logtail-rails' request events go only to Better Stack, so stdout keeps Rails' own lines.
  # Rails' log subscribers and Rack logger stay in place for the same reason. ErrorEvent is off
  # because Rails already logs every unhandled exception; it would ship each one twice.
  Logtail.config.logger = betterstack_logger
  [
    Logtail::Integrations::ActionController,
    Logtail::Integrations::ActionView,
    Logtail::Integrations::ActiveRecord,
    Logtail::Integrations::Rails::RackLogger,
    Logtail::Integrations::Rails::ErrorEvent,
    Logtail::Integrations::Rack::HTTPContext,
  ].each { |integration| integration.enabled = false }
  # Above DebugExceptions, so unhandled exceptions carry the request too (see RequestContext).
  Rails.application.config.middleware.insert_after ActionDispatch::RequestId, Betterstack::RequestContext
  # Only the user's id: logtail-rack would otherwise send names and emails.
  Logtail::Integrations::Rack::UserContext.custom_user_hash = lambda do |env|
    (user = env["warden"]&.user) && { id: user.id }
  end
  # Request events (info level) record headers; never send credentials. One event per request.
  Logtail::Integrations::Rack::HTTPEvents.http_header_filters = %w[
    Authorization Proxy-Authorization Cookie Set-Cookie X-CSRF-Token
    api-key x-algolia-api-key health-check-token
  ]
  Logtail::Integrations::Rack::HTTPEvents.collapse_into_single_event = true

  # Exceptions Rails already turns into responses (404s, CSRF, routing, Pundit; see
  # rescue_responses) are logged with full traces. Keep them on stdout, not in Better Stack.
  rescued_classes = Regexp.union(ActionDispatch::ExceptionWrapper.rescue_responses.keys)
  rescued_exception = /\A\s*(?:\[[^\]]*\]\s*)*(?:#{rescued_classes}) \(/
  # Rails' own request lines duplicate the request event above.
  request_line = /\A(?:Started [A-Z]+ "|  Parameters: |Completed \d{3} )/
  Logtail.config.filter_sent_to_better_stack do |entry|
    message = entry.message.to_s
    message.match?(rescued_exception) || (entry.event.nil? && message.match?(request_line))
  end

  # Logtail::Logger must not respond to #tagged: BroadcastLogger runs a tagged block once per
  # logger that does, so ActiveJob#perform_now would run every job twice.
  Rails.logger.broadcast_to(betterstack_logger)
end
