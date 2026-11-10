require "rails_helper"

RSpec.describe "Cloudflare tasks", type: :task do
  before do
    Rake.application["cloudflare:update_configs"].reenable
    allow(CloudflareConfig::Update).to receive(:call)
  end

  describe "#update_configs" do
    it "doesn't run if Cloudflare isn't configured" do
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_API_TOKEN").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_ACCOUNT_ID").and_return(nil)

      Rake::Task["cloudflare:update_configs"].invoke

      expect(CloudflareConfig::Update).not_to have_received(:call)
    end

    it "doesn't run if SKIP_CLOUDFLARE_CONFIG_UPDATE is set" do
      allow(ENV).to receive(:[]).with("SKIP_CLOUDFLARE_CONFIG_UPDATE").and_return("true")

      Rake::Task["cloudflare:update_configs"].invoke

      expect(CloudflareConfig::Update).not_to have_received(:call)
    end

    it "runs when Cloudflare credentials are configured" do
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_API_TOKEN").and_return("token_123")
      allow(ApplicationConfig).to receive(:[]).with("CLOUDFLARE_ACCOUNT_ID").and_return("acct_123")

      Rake::Task["cloudflare:update_configs"].invoke

      expect(CloudflareConfig::Update).to have_received(:call)
    end
  end
end
