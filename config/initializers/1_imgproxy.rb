# This file has to run before Carrierwave

Imgproxy.configure do |config|
  # imgproxy endpoint
  #
  # Full URL to where your imgproxy lives.
  #
  config.endpoint = nil # Images::Optimizer will set the endpoint because Settings::General is not ready during boot

  # Next, you have to provide your signature key and salt.
  # If unsure, check out https://github.com/imgproxy/imgproxy/blob/master/docs/configuration.md first.

  # Hex-encoded signature key
  config.key = ApplicationConfig["IMGPROXY_KEY"]
  # Hex-encoded signature salt
  config.salt = ApplicationConfig["IMGPROXY_SALT"]

  # Base64 encode all URLs
  config.base64_encode_urls = true

  # Always escape plain URLs
  # config.always_escape_plain_urls = true
end
