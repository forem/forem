FastlyRails.configure do |c|

  c.api_key = ApplicationConfig['FASTLY_API_KEY']  # Fastly api key, required
  c.max_age = 86500                  # time in seconds, optional, defaults to 2592000 (30 days)
  c.service_id = ApplicationConfig['FASTLY_SERVICE_ID']   # The Fastly service you will be using, required
  c.stale_if_error = 26400
  c.purging_enabled = Rails.env.production? # No need to configure a client locally (AVAILABLE ONLY AS OF 0.4.0)

end
