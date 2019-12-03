module ValidRequest
  extend ActiveSupport::Concern

  def valid_request_origin?
    # This manually does what it was supposed to do on its own.
    # We were getting this issue:
    # HTTP Origin header (https://dev.to) didn't match request.base_url (http://dev.to)
    # Not sure why, but once we work it out, we can delete this method.
    # We are at least secure for now.
    return if Rails.env.test?

    if request.referer.present?
      request.referer.start_with?(ApplicationConfig["APP_PROTOCOL"].to_s + ApplicationConfig["APP_DOMAIN"].to_s)
    else
      raise InvalidAuthenticityToken, NULL_ORIGIN_MESSAGE if request.origin == "null"

      request.origin.nil? || request.origin.gsub("https", "http") == request.base_url.gsub("https", "http")
    end
  end
end
