require "rails_helper"

RSpec.describe CloudflareSaas do
  before do
    allow(ApplicationConfig).to receive(:[]).and_call_original
  end

  describe ".enabled?" do
    it "is true when the API token and zone are configured" do
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_SAAS_API_TOKEN").and_return("token")
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_SAAS_ZONE_ID").and_return("zone")

      expect(described_class.enabled?).to be(true)
    end

    it "is false when either value is missing" do
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_SAAS_API_TOKEN").and_return("token")
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_SAAS_ZONE_ID").and_return("")

      expect(described_class.enabled?).to be(false)
    end
  end

  describe ".cname_target" do
    it "defaults to cname on the app domain" do
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_SAAS_CNAME_TARGET").and_return(nil)
      allow(Settings::General).to receive(:app_domain).and_return("forem.com")

      expect(described_class.cname_target).to eq("cname.forem.com")
    end

    it "uses the configured target when present" do
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_SAAS_CNAME_TARGET").and_return("custom.forem.com")

      expect(described_class.cname_target).to eq("custom.forem.com")
    end
  end
end
