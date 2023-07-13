require_relative "../../app/lib/middlewares/set_cookie_domain"
require_relative "../../app/lib/middlewares/set_dev_client_geo"
require_relative "../../app/lib/middlewares/set_time_zone"

Rails.configuration.middleware.use(Middlewares::SetCookieDomain) if Rails.env.production?

# Include middleware to ensure timezone for browser requests for Capybara specs
# matches the random zonebie timezone set at the beginning of our spec run
Rails.configuration.middleware.use(Middlewares::SetTimeZone) if Rails.env.test?

# Include middleware to fake "HTTP_CLIENT_GEO" header using a `client_geo` query
# param in development mode
Rails.configuration.middleware.use(Middlewares::SetDevClientGeo) if Rails.env.development?
