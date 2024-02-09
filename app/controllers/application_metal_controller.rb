class ApplicationMetalController < ActionController::Metal
  # Any shared behavior across metal-oriented controllers can go here.

  # These are basic things we likely want for any metal controllers
  include ActionController::Cookies
  include ActionController::RequestForgeryProtection
  # ActionController modules which may not be used in each controller can go in
  # the specific controller.

  protect_from_forgery with: :exception, prepend: true unless Rails.env.test?

  include SessionCurrentUser
  include ValidRequest

  def logger
    ActionController::Base.logger
  end

  def client_geolocation
    if session_current_user_id
      request.headers["X-Client-Geo"]
    else
      request.headers["X-Cacheable-Client-Geo"]
    end
  end
  helper_method :client_geolocation
end
