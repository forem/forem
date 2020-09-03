class SessionsController < Devise::SessionsController
  def create
    delete_legacy_cookie

    super
  end

  def destroy
    delete_legacy_cookie

    # Let's say goodbye to all the cookies when someone signs out.
    cookies.clear(domain: cookie_domain)

    super
  end

  private

  def legacy_cookie_domain
    Rails.env.production? ? ApplicationConfig["APP_DOMAIN"] : nil
  end

  def cookie_domain
    ".#{legacy_cookie_domain}"
  end

  # TODO: this code is a hotfix, we should remove it after 09/18/2020.
  def delete_legacy_cookie
    # Deleting the session cookie with the legacy app domain, which does NOT include a preceding dot.
    # This should fix the double cookie scenario.
    cookies.delete(ApplicationConfig["SESSION_KEY"], domain: legacy_cookie_domain)
  end
end
