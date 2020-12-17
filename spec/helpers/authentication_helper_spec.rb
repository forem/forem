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

  describe "#available_providers_array" do
    it "returns array of available providers in lowercase" do
      provider = Authentication::Providers.available.first
      allow(Authentication::Providers).to receive(:available).and_return([provider])

      expected_result = provider.to_s
      expect(helper.available_providers_array).to match_array([expected_result])
    end
  end

  describe "#provider_keys_configured?(provider)" do
    let(:provider) { "facebook" }

    it "returns true if provider key and secret both present" do
      allow(SiteConfig).to receive(:"#{provider}_key").and_return("someKey")
      allow(SiteConfig).to receive(:"#{provider}_secret").and_return("someSecret")

      expect(provider_keys_configured?(provider)).to be(true)
    end

    it "returns false if either provider key or secret is missing" do
      allow(SiteConfig).to receive(:"#{provider}_key").and_return("someKey")
      allow(SiteConfig).to receive(:"#{provider}_secret").and_return("")

      expect(provider_keys_configured?(provider)).to be(false)

      allow(SiteConfig).to receive(:"#{provider}_key").and_return("")
      allow(SiteConfig).to receive(:"#{provider}_secret").and_return("someSecret")

      expect(provider_keys_configured?(provider)).to be(false)
    end
  end

  describe "tooltip classes, attributes and content" do
    context "when invite-only-mode enabled and no enabled registration options" do
      before do
        allow(SiteConfig).to receive(:invite_only_mode).and_return(true)
        allow(SiteConfig).to receive(:authentication_providers).and_return([])
        allow(SiteConfig).to receive(:allow_email_password_registration).and_return(false)
      end

      it "returns 'crayons-tooltip' class for relevant helpers" do
        expect(tooltip_class_on_auth_provider_enablebtn).to eq("crayons-tooltip")
      end

      it "returns 'disabled' attribute for relevant helper" do
        expect(disabled_attr_on_auth_provider_enablebtn).to eq("disabled")
      end

      it "returns appropriate text for 'tooltip_text_email_or_auth_provider_btns' helper" do
        tooltip_text = "You cannot do this until you disable Invite Only Mode"

        expect(tooltip_text_email_or_auth_provider_btns).to eq(tooltip_text)
      end
    end
  end
end
