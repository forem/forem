require_relative "../../app/lib/middlewares/restore_original_host"
require_relative "../../app/lib/middlewares/set_cookie_domain"
require_relative "../../app/lib/middlewares/set_subforem"
require_relative "../../app/lib/middlewares/set_time_zone"

Rails.configuration.middleware.insert(0, Middlewares::RestoreOriginalHost)
Rails.configuration.middleware.use(Middlewares::SetSubforem)
Rails.configuration.middleware.use(Middlewares::SetCookieDomain) if Rails.env.production?

# Remove JQuery::FileUpload::Rails::Middleware injected by s3_direct_upload.
# It is only used for legacy IE <= 9 iframe upload transports, and its post-response
# `@request.params` check parses multipart POST bodies without handling EOFError on
# truncated/empty requests (causing unhandled 500s on 404/catch-all routes).
Rails.configuration.middleware.delete(JQuery::FileUpload::Rails::Middleware)

# Include middleware to ensure timezone for browser requests for Capybara specs
# matches the random zonebie timezone set at the beginning of our spec run
Rails.configuration.middleware.use(Middlewares::SetTimeZone) if Rails.env.test?
