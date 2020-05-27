require "rails_helper"

RSpec.describe Authentication::Providers, type: :service do
  describe ".get!" do
    xit "raises an exception if a provider is not available" do
      expect do
        described_class.get!(:unknown)
      end.to raise_error(Authentication::Errors::ProviderNotFound)
    end

    xit "raises an exception if a provider is available but not enabled" do
      allow(SiteConfig).to receive(:authentication_providers).and_return(%w[github])

      expect do
        described_class.get!(:twitter)
      end.to raise_error(Authentication::Errors::ProviderNotEnabled)
    end

    xit "loads the correct provider class" do
      is_subclass_of = (
        described_class.get!(:twitter) < Authentication::Providers::Provider
      )
      expect(is_subclass_of).to be(true)
    end
  end

  describe ".available" do
    xit "lists the available providers" do
      available_providers = %i[github twitter]
      expect(described_class.available).to eq(available_providers)
    end
  end

  describe ".enabled" do
    xit "lists all available providers" do
      expect(described_class.available).to eq(described_class.enabled)
    end

    context "when one of the available providers is disabled" do
      xit "only lists those that remain enabled" do
        allow(SiteConfig).to receive(:authentication_providers).and_return(%w[github])

        expect(described_class.enabled).to eq(%i[github])
      end
    end
  end

  describe ".enabled?" do
    xit "returns true if a provider is enabled" do
      allow(SiteConfig).to receive(:authentication_providers).and_return(%w[github])

      expect(described_class.enabled?(:github)).to be(true)
    end

    xit "returns false if a provider is not enabled" do
      allow(SiteConfig).to receive(:authentication_providers).and_return(%w[twitter])

      expect(described_class.enabled?(:github)).to be(false)
    end
  end
end
