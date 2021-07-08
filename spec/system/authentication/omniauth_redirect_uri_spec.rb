require "rails_helper"

RSpec.describe "Omniauth redirect_uri", type: :system do
  let!(:test_app_domain) { Settings::General.app_domain }

  # Avoid messing with other tests by resetting back Settings::General.app_domain
  after { Settings::General.app_domain = test_app_domain }

  # Apple auth is in Beta so we need to enable the Feature Flag to test it
  before { Flipper.enable(:apple_auth) }

  def provider_redirect_regex(provider_name)
    # URL encoding translates the query params (i.e. colons/slashes/etc)
    %r{
      /users/auth/#{provider_name}
      \?callback_url=#{ERB::Util.url_encode(URL.protocol)}
      #{ERB::Util.url_encode(Settings::General.app_domain)}
      #{ERB::Util.url_encode("/users/auth/#{provider_name}/callback")}
    }x
  end

  it "relies on Settings::General.app_domain to generate correct callbacks_url" do
    allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
    visit sign_up_path
    Authentication::Providers.available.each do |provider_name|
      provider_auth_button = find("button.crayons-btn--brand-#{provider_name}")
      provider_auth_url = provider_auth_button.find(:xpath, "..")["action"]
      expect(provider_auth_url).to match(provider_redirect_regex(provider_name))
    end

    Settings::General.app_domain = "test.forem.com"
    visit sign_up_path

    # After an update the callback_url should now match Settings::General.app_domain
    Authentication::Providers.available.each do |provider_name|
      provider_auth_button = find("button.crayons-btn--brand-#{provider_name}")
      provider_auth_url = provider_auth_button.find(:xpath, "..")["action"]
      expect(provider_auth_url).to match(provider_redirect_regex(provider_name))
    end
  end
end
