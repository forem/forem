class Ahoy::Store < Ahoy::DatabaseStore
end

# set to true for JavaScript tracking
Ahoy.api = true

# set to false to disable geocode tracking
Ahoy.geocode = false

# only create visits server-side when needed for events and `visitable`
Ahoy.server_side_visits = :when_needed
