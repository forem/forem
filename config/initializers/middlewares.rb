require_relative "../../app/lib/middlewares/set_cookie_domain"
require_relative "../../app/lib/middlewares/set_subforem"
require_relative "../../app/lib/middlewares/set_time_zone"

Rails.configuration.middleware.use(Middlewares::SetCookieDomain) if Rails.env.production?

# Include middleware to ensure timezone for browser requests for Capybara specs
# matches the random zonebie timezone set at the beginning of our spec run
Rails.configuration.middleware.use(Middlewares::SetTimeZone) if Rails.env.test?

Rails.configuration.middleware.use(Middlewares::SetSubforem)
