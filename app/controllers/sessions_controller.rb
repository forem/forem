class SessionsController < Devise::SessionsController
  def create
    delete_legacy_cookie

    super
  end

  def destroy
    # Let's say goodbye to all the cookies when someone signs out.
    cookies.clear(domain: cookie_domain)

    delete_legacy_cookie

    super
  end

  private

  def cookie_domain
    Rails.env.production? ? ApplicationConfig["APP_DOMAIN"] : nil
  end

  # NOTE: this code is a hotfix, and shall be removed soon (around 2 weeks from deployment)
  def delete_legacy_cookie
    domain = cookie_domain

    return unless domain&.starts_with?(".")

    # Deleting the session cookie with the previous app domain, the one without the leading dot.
    # This should fix the double cookie scenario
    domain_without_leading_dot = domain.gsub(/\A./, "")
    cookies.delete(ApplicationConfig["SESSION_KEY"], domain: domain_without_leading_dot)
  end
end
