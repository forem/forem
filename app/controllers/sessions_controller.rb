class SessionsController < Devise::SessionsController
  def destroy
    # Let's say goodbye to all the cookies when someone signs out.
    domain = Rails.env.production? ? ApplicationConfig["APP_DOMAIN"] : nil
    cookies.clear(domain: domain)

    super
  end
end
