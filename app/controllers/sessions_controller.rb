class SessionsController < Devise::SessionsController
  include Devise::Controllers::Rememberable
  def create
    delete_legacy_cookie
    self.resource = warden.authenticate!(auth_options)
    set_flash_message!(:notice, :signed_in)
    sign_in(resource_name, resource)
    yield resource if block_given?
    remember_me(resource)
    respond_with resource, location: after_sign_in_path_for(resource)
  end

  def destroy
    delete_legacy_cookie

    # Let's say goodbye to all the cookies when someone signs out.
    cookies.clear(domain: cookie_domain)

    super
  end

  private

  def legacy_cookie_domain
    Rails.env.production? ? SiteConfig.app_domain : nil
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
