require "rails_helper"

RSpec.describe App, type: :lib do
  describe ".protocol" do
    it "returns the value of APP_PROTOCOL env variable" do
      expect(described_class.protocol).to eq(ApplicationConfig["APP_PROTOCOL"])
    end
  end

  describe ".domain" do
    it "returns the value of APP_DOMAIN env variable" do
      expect(described_class.domain).to eq(ApplicationConfig["APP_DOMAIN"])
    end
  end

  describe ".url" do
    before do
      allow(ApplicationConfig).to receive(:[]).with("APP_PROTOCOL").and_return("https://")
      allow(ApplicationConfig).to receive(:[]).with("APP_DOMAIN").and_return("dev.to")
    end

    it "creates the correct base app URL" do
      expect(described_class.url).to eq("https://dev.to")
    end

    it "creates a URL with a path" do
      expect(described_class.url("internal")).to eq("https://dev.to/internal")
    end

    it "creates the correct URL even if the path starts with a slash" do
      expect(described_class.url("/internal")).to eq("https://dev.to/internal")
    end

    it "works when called with an URI object" do
      uri = URI::Generic.build(path: "internal", fragment: "test")
      expect(described_class.url(uri)).to eq("https://dev.to/internal#test")
    end
  end
end
