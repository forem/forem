module Ahoy
  class Store < Ahoy::DatabaseStore
  end
end

# set to true to mask ip addresses
Ahoy.mask_ips = true

# set to false to switch from cookies to anonymity sets
Ahoy.cookies = false

# set to false to disable geocode tracking
Ahoy.geocode = false

# Settings::General.ahoy_tracking is only available after initialization
Rails.configuration.after_initialize do
  # In local development the setting may have changed so this helps maintain
  # consistency when running tests locally
  ahoy_enabled = Settings::General.ahoy_tracking || Rails.env.test?

  # set to true for JavaScript tracking
  Ahoy.api = ahoy_enabled

  # only create visits server-side when needed for events and `visitable`
  Ahoy.server_side_visits = ahoy_enabled ? :when_needed : false
rescue StandardError
  # When setting up the local environment there's a chance the DB won't be
  # available or migrations haven't run yet
  Rails.logger.warn "Warning: Ahoy didn't initialize correctly"
  Rails.logger.warn "Omit this message if running a rake task (i.e. `rails db:create`)"
end
