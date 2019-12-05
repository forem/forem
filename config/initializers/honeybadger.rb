Honeybadger.configure do |config|
  # Can be used to implement more programatic error handling
  # https://docs.honeybadger.io/lib/ruby/getting-started/ignoring-errors.html#ignore-programmatically
  config.api_key = ApplicationConfig["HONEYBADGER_API_KEY"]
  config.revision = ApplicationConfig["HEROKU_SLUG_COMMIT"]
  config.exceptions.ignore += [Pundit::NotAuthorizedError, ActiveRecord::RecordNotFound]
  config.request.filter_keys += %w[authorization]
end
