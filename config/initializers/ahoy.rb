module Ahoy
  class Store < Ahoy::DatabaseStore
  end
end

# set to true to mask ip addresses
Ahoy.mask_ips = true

# set to false to switch from cookies to anonymity sets
Ahoy.cookies = false

# set to true for JavaScript tracking
Ahoy.api = true

# set to false to disable geocode tracking
Ahoy.geocode = false

# only create visits server-side when needed for events and `visitable`
Ahoy.server_side_visits = :when_needed
