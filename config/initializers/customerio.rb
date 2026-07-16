# Customer.io App API client used by DeliveryMethods::CustomerIo for
# transactional email sends. Safe to construct with a nil key: nothing calls
# it unless ForemInstance.customerio_enabled? (key present) routes mail here.
CUSTOMERIO_API = Customerio::APIClient.new(ApplicationConfig["CUSTOMERIO_APP_KEY"])
