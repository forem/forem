Rails.configuration.middleware.use(Middlewares::SetCookieDomain) if Rails.env.production?

# Include middleware to ensure timezone for browser requests for Capybara specs
# matches the random zonebie timezone set at the beginning of our spec run
Rails.configuration.middleware.use(Middlewares::SetTimeZone) if Rails.env.test?
