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
      allow(SiteConfig).to receive(:authentication_providers).and_return(described_class.available)

      is_subclass_of = (
        described_class.get!(:twitter) < Authentication::Providers::Provider
      )
      expect(is_subclass_of).to be(true)
    end
  end

  describe ".available" do
    it "lists the available providers" do
      available_providers = %i[facebook github twitter]
      expect(described_class.available).to eq(available_providers)
    end
  end

  describe ".enabled" do
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
end
