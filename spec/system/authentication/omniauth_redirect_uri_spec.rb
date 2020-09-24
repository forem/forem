require "rails_helper"

RSpec.describe "Omniauth redirect_uri", type: :system do
  let!(:test_app_domain) { SiteConfig.app_domain }

  # Avoid messing with other tests by resetting back SiteConfig.app_domain
  after { SiteConfig.app_domain = test_app_domain }

  def provider_redirect_regex(provider_name)
    %r{
      /users/auth/#{provider_name}
      \?callback_url=https%3A%2F%2F
      #{SiteConfig.app_domain}%2Fusers%2Fauth%2F#{provider_name}%2Fcallback
    }x
  end

  it "relies on SiteConfig.app_domain to generate correct callbacks_url" do
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
