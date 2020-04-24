require "rails_helper"

RSpec.describe Authentication::Providers, type: :service do
  describe ".get!" do
    it "raises an exception if a provider is not available" do
      expect do
        described_class.get!(:unknown)
      end.to raise_error(Authentication::Errors::ProviderNotFound)
    end

    it "raises an exception if a provider is available but not enabled" do
      allow(SiteConfig).to receive(:authentication_providers).and_return(%w[github])

      expect do
        described_class.get!(:twitter)
      end.to raise_error(Authentication::Errors::ProviderNotEnabled)
    end

    it "loads the correct provider class" do
      is_subclass_of = (
        described_class.get!(:twitter) < Authentication::Providers::Provider
      )
      expect(is_subclass_of).to be(true)
    end
  end

  describe ".available" do
    it "lists the available providers" do
      available_providers = %i[github twitter]
      expect(described_class.available).to eq(available_providers)
    end
  end

  describe ".enabled" do
    it "lists all available providers" do
      expect(described_class.available).to eq(described_class.enabled)
    end

    context "when one of the available providers is disabled" do
      it "only lists those that remain enabled" do
        allow(SiteConfig).to receive(:authentication_providers).and_return(%w[github])

        expect(described_class.enabled).to eq(%i[github])
      end
    end
  end

  describe ".enabled?" do
    it "returns true if a provider is enabled" do
      allow(SiteConfig).to receive(:authentication_providers).and_return(%w[github])

      expect(described_class.enabled?(:github)).to be(true)
    end

    it "returns false if a provider is not enabled" do
      allow(SiteConfig).to receive(:authentication_providers).and_return(%w[twitter])

      expect(described_class.enabled?(:github)).to be(false)
    end
  end

  describe ".authentication_path" do
    it "returns the correct authentication path for given provider" do
      expected_path = Rails.application.routes.url_helpers.user_github_omniauth_authorize_path
      expect(described_class.authentication_path(:github)).to eq(expected_path)
    end

    it "supports additional parameters" do
      path = described_class.authentication_path(:github, state: "state")
      expect(path).to include("state=state")
    end
  end

  describe ".sign_in_path" do
    let(:expected_path) do
      "/users/auth/github?callback_url=http%3A%2F%2Flocalhost%3A3000%2Fusers%2Fauth%2Fgithub%2Fcallback"
    end

    it "returns the correct sign in URL for given provider" do
      expect(described_class.sign_in_path(:github)).to eq(expected_path)
    end

    it "supports additional parameters" do
      path = described_class.sign_in_path(:github, state: "state")
      expect(path).to include("state=state")
    end

    it "does not override the callback_url parameter" do
      path = described_class.sign_in_path(:github, callback_url: "https://example.com/callback")
      expect(path).to eq(expected_path)
    end
  end
end
