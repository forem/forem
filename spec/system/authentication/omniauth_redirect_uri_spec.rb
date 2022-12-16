require "rails_helper"

RSpec.describe "Omniauth redirect_uri" do
  let!(:test_app_domain) { Settings::General.app_domain }

  # Avoid messing with other tests by resetting back Settings::General.app_domain
  after { Settings::General.app_domain = test_app_domain }

  before do
    allow(Settings::Authentication).to receive(:providers).and_return(Authentication::Providers.available)
  end

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
    visit sign_up_path
    Authentication::Providers.available.each do |provider_name|
      next if provider_name == :twitter2

      provider_auth_button = find("button.crayons-btn--brand-#{provider_name}")
      provider_auth_url = provider_auth_button.find(:xpath, "..")["action"]
      expect(provider_auth_url).to match(provider_redirect_regex(provider_name))
    end

    Settings::General.app_domain = "test.forem.com"
    visit sign_up_path

    # After an update the callback_url should now match Settings::General.app_domain
    Authentication::Providers.available.each do |provider_name|
      next if provider_name == :twitter2

      provider_auth_button = find("button.crayons-btn--brand-#{provider_name}")
      provider_auth_url = provider_auth_button.find(:xpath, "..")["action"]
      expect(provider_auth_url).to match(provider_redirect_regex(provider_name))
    end
  end

  it "generates correct callbacks_url for Twitter OAuth2" do
    allow(FeatureFlag).to receive(:enabled?).with(:twitter_oauth2).and_return(true)
    visit sign_up_path
    provider_auth_button = find("button.crayons-btn--brand-twitter")
    provider_auth_url = provider_auth_button.find(:xpath, "..")["action"]
    expect(provider_auth_url).to match(provider_redirect_regex(:twitter2))
  end
end
