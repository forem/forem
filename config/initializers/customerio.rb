# Customer.io App API client used by DeliveryMethods::CustomerIo for
# transactional email sends. Safe to construct with a nil key: nothing calls
# it unless ForemInstance.customerio_enabled? (key present) routes mail here.
CUSTOMERIO_API = Customerio::APIClient.new(ApplicationConfig["CUSTOMERIO_APP_KEY"])

# Track API client used by DeliveryMethods::CustomerIoEvent to emit the event
# that triggers a Customer.io campaign. Separate credentials from the App API
# above: the Track API authenticates with the site id and its own api key.
# Equally safe to construct with nil credentials -- nothing calls it unless
# ForemInstance.customerio_track_enabled? routes mail here.
CUSTOMERIO_TRACK_API = Customerio::Client.new(
  ApplicationConfig["CUSTOMERIO_SITE_ID"],
  ApplicationConfig["CUSTOMERIO_TRACK_API_KEY"],
)
