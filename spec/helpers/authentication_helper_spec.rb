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

  describe "#signed_up_with" do
    it "returns an authentication reminder when a user auths with a provider" do
      providers = Authentication::Providers.available.last(2)
      allow(Authentication::Providers).to receive(:enabled).and_return(providers)
      allow(user).to receive(:identities).and_return(user.identities.where(provider: providers))

      expect(helper.signed_up_with(user)).to match(/GitHub and Twitter/)
      expect(helper.signed_up_with(user)).to match(/use any of those/)
    end

    it "returns an authentication reminder when a user signs up with email" do
      allow(Authentication::Providers).to receive(:enabled).and_return([])

      expect(helper.signed_up_with(user)).to match(/Email & Password/)
      expect(helper.signed_up_with(user)).to match(/use that/)
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

  describe "#authentication_provider_enabled?" do
    before do
      allow(ForemInstance).to receive(:private?).and_return(false)
      allow(Settings::Authentication).to receive(:providers).and_return(%i[twitter github])
    end

    it "returns true when a provider has been enabled" do
      expect(helper.authentication_provider_enabled?(Authentication::Providers::Twitter)).to be true
      expect(helper.authentication_provider_enabled?(Authentication::Providers::Github)).to be true
    end

    it "returns false when a provider has not yet been enabled" do
      expect(helper.authentication_provider_enabled?(Authentication::Providers::Facebook)).to be false
      expect(helper.authentication_provider_enabled?(Authentication::Providers::Apple)).to be false
    end
  end

  describe "tooltip classes, attributes and content" do
    context "when invite-only-mode enabled and no enabled registration options" do
      before do
        allow(ForemInstance).to receive(:private?).and_return(true)
        allow(Settings::Authentication).to receive(:providers).and_return([])
        allow(Settings::Authentication).to receive(:allow_email_password_registration).and_return(false)
      end

      it "returns 'crayons-tooltip' class for relevant helpers" do
        expect(tooltip_class_on_auth_provider_enablebtn).to eq("crayons-tooltip")
      end

      it "returns 'disabled' attribute for relevant helper" do
        expect(disabled_attr_on_auth_provider_enable_btn).to eq("disabled")
      end

      it "returns appropriate text for 'tooltip_text_email_or_auth_provider_btns' helper" do
        tooltip_text = "You cannot do this until you disable Invite Only Mode"

        expect(tooltip_text_email_or_auth_provider_btns).to eq(tooltip_text)
      end
    end
  end
end
