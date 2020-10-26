require "rails_helper"

RSpec.describe AuthenticationHelper, type: :helper do
  let(:user) { create(:user, :with_identity) }

  before do
    omniauth_mock_providers_payload
  end

  describe "#authentication_enabled_providers_for_user" do
    it "returns an enabled provider" do
      provider = Authentication::Providers.available.first
      allow(Authentication::Providers).to receive(:enabled).and_return([provider])
      allow(user).to receive(:identities).and_return(user.identities.where(provider: provider))

      expected_result = Authentication::Providers.get!(provider)
      expect(helper.authentication_enabled_providers_for_user(user)).to match_array([expected_result])
    end

    it "does not return a disabled provider" do
      disabled_provider = %i[github]
      providers = Authentication::Providers.available - disabled_provider
      allow(Authentication::Providers).to receive(:enabled).and_return(providers)
      user = create(:user, :with_identity)

      provider_names = helper.authentication_enabled_providers_for_user(user).map(&:provider_name)
      expect(provider_names).not_to include(disabled_provider)
    end
  end

  describe "#recaptcha_configured_and_enabled?" do
    context "when recaptcha is enabled" do
      before do
        allow(SiteConfig).to receive(:require_captcha_for_email_password_registration).and_return(true)
      end

      it "returns true if both site & secret keys present" do
        allow(SiteConfig).to receive(:recaptcha_secret_key).and_return("someSecretKey")
        allow(SiteConfig).to receive(:recaptcha_site_key).and_return("someSiteKey")

        expect(recaptcha_configured_and_enabled?).to be(true)
      end

      it "returns false if site or secret key missing" do
        allow(SiteConfig).to receive(:recaptcha_site_key).and_return("")

        expect(recaptcha_configured_and_enabled?).to be(false)
      end
    end

    it "returns false if recaptcha disabled for email signup" do
      allow(SiteConfig).to receive(:require_captcha_for_email_password_registration).and_return(false)

      expect(recaptcha_configured_and_enabled?).to be(false)
    end
  end
end
