# Monkey patches to solve historical request issues
module ValidRequest
  extend ActiveSupport::Concern

  def valid_request_origin?
    # This manually does what it was supposed to do on its own.
    # We were getting this issue:
    # HTTP Origin header (https://dev.to) didn't match request.base_url (http://dev.to)
    # Not sure why, but once we work it out, we can delete this method.
    # We are at least secure for now.
    return if Rails.env.test?

    if (referer = request.referer).present?
      referer.start_with?(URL.url)
    else
      origin = request.origin
      if origin == "null"
        raise ::ActionController::InvalidAuthenticityToken, ::ApplicationController::NULL_ORIGIN_MESSAGE
      end

      origin.nil? || origin.gsub("https", "http") == request.base_url.gsub("https", "http")
    end
  end

  def _compute_redirect_to_location(request, options) #:nodoc:
    case options
    # Yet another monkeypatch required to send proper protocol out.
    # In this case we make sure the redirect ends in the app protocol.
    # This is the same as the base Rails method except URL.protocol
    # is used instead of request.protocol.
    when %r{\A([a-z][a-z\d\-+.]*:|//).*}i
      options
    when String
      "#{URL.protocol || request.protocol}#{request.host_with_port}#{options}"
    when Proc
      _compute_redirect_to_location request, instance_eval(&options)
    else
      url_for(options)
    end.delete("\0\r\n")
  end
end
