require "rails_helper"

RSpec.describe "Fastly tasks", type: :task do
  before do
    Rake.application["fastly:update_configs"].reenable
    allow(FastlyConfig::Update).to receive(:call)
  end

  describe "#update_configs" do
    it "doesn't run if Fastly isn't configured" do
      allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return(nil)
      allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return(nil)

      Rake::Task["fastly:update_configs"].invoke

      expect(FastlyConfig::Update).not_to have_received(:call)
    end

    it "doesn't run if SKIP_FASTLY_CONFIG_UPDATE is set" do
      allow(ENV).to receive(:[]).with("SKIP_FASTLY_CONFIG_UPDATE").and_return("true")

      Rake::Task["fastly:update_configs"].invoke

      expect(FastlyConfig::Update).not_to have_received(:call)
    end

    it "does run if Fastly is configured" do
      allow(ApplicationConfig).to receive(:[]).with("FASTLY_API_KEY").and_return("123")
      allow(ApplicationConfig).to receive(:[]).with("FASTLY_SERVICE_ID").and_return("123")

      Rake::Task["fastly:update_configs"].invoke

      expect(FastlyConfig::Update).to have_received(:call)
    end
  end
end
