require "rails_helper"

describe ApplicationConfig do
  it "logs warning if key is not found" do
    allow(Rails.logger).to receive(:debug)
    described_class["missing"]
    expect(Rails.logger).to have_received(:debug)
  end

  describe ".app_domain_no_port" do
    it "handles plain subdomain only name" do
      setup_app_domain("renner")

      expect(described_class.app_domain_no_port).to eq "renner"
    end

    it "handles plain domain name" do
      setup_app_domain("renner.ngrok.io")

      expect(described_class.app_domain_no_port).to eq "renner.ngrok.io"
    end

    it "handles domain with port" do
      setup_app_domain("renner:3000")

      expect(described_class.app_domain_no_port).to eq "renner"
    end

    it "handles domain with schema and port" do
      setup_app_domain("http://renner:4000")

      expect(described_class.app_domain_no_port).to eq "renner"
    end

    private

    def setup_app_domain(app_domain)
      allow(ApplicationConfig).to receive(:[]).with("APP_DOMAIN").and_return(app_domain)
    end
  end
end
