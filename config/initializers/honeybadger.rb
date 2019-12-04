Honeybadger.configure do |config|
  # Can be used to implement more programatic error handling
  # https://docs.honeybadger.io/lib/ruby/getting-started/ignoring-errors.html#ignore-programmatically
  config.api_key = ENV.fetch("HONEYBADGER_API_KEY", "api_key")
end
