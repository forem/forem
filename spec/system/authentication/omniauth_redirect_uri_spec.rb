require "rails_helper"

RSpec.describe "Omniauth redirect_uri", type: :system do
  let!(:test_app_domain) { SiteConfig.app_domain }

  # Avoid messing with other tests by resetting back SiteConfig.app_domain
  after { SiteConfig.app_domain = test_app_domain }

  def provider_redirect_regex(provider_name)
    # URL encoding translates the query params (i.e. colons/slashes/etc)
    %r{
      /users/auth/#{provider_name}
      \?callback_url=#{ERB::Util.url_encode(URL.protocol)}
      #{ERB::Util.url_encode(SiteConfig.app_domain)}
      #{ERB::Util.url_encode("/users/auth/#{provider_name}/callback")}
    }x
  end

  it "relies on SiteConfig.app_domain to generate correct callbacks_url" do
    allow(SiteConfig).to receive(:authentication_providers).and_return(Authentication::Providers.available)
    visit sign_up_path
    Authentication::Providers.available.each do |provider_name|
      provider_auth_url = find("a.crayons-btn--brand-#{provider_name}")["href"]
      expect(provider_auth_url).to match(provider_redirect_regex(provider_name))
    end

    SiteConfig.app_domain = "test.forem.com"
    visit sign_up_path

    # After an update the callback_url should now match SiteConfig.app_domain
    Authentication::Providers.available.each do |provider_name|
      provider_auth_url = find("a.crayons-btn--brand-#{provider_name}")["href"]
      expect(provider_auth_url).to match(provider_redirect_regex(provider_name))
    end
  end
end
