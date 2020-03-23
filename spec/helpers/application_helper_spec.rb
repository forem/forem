require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  describe "#community_qualified_name" do
    it "equals to the full qualified community name" do
      expected_name = "The #{ApplicationConfig['COMMUNITY_NAME']} Community"
      expect(helper.community_qualified_name).to eq(expected_name)
    end
  end

  describe "#beautified_url" do
    it "strips the protocol" do
      expect(helper.beautified_url("https://github.com")).to eq("github.com")
    end

    it "strips params" do
      expect(helper.beautified_url("https://github.com?a=3")).to eq("github.com")
    end

    it "strips the last forward slash" do
      expect(helper.beautified_url("https://github.com/")).to eq("github.com")
    end

    it "does not strip the path" do
      expect(helper.beautified_url("https://github.com/rails")).to eq("github.com/rails")
    end
  end

  describe "#cache_key_heroku_slug" do
    it "does nothing when HEROKU_SLUG_COMMIT is not set" do
      allow(ApplicationConfig).to receive(:[]).with("HEROKU_SLUG_COMMIT").and_return(nil)
      expect(helper.cache_key_heroku_slug("cache-me")).to eq("cache-me")
    end

    it "appends the HEROKU_SLUG_COMMIT if it is set" do
      allow(ApplicationConfig).to receive(:[]).with("HEROKU_SLUG_COMMIT").and_return("abc123")
      expect(helper.cache_key_heroku_slug("cache-me")).to eq("cache-me-abc123")
    end
  end

  describe "#app_url" do
    before do
      allow(ApplicationConfig).to receive(:[]).with("APP_PROTOCOL").and_return("https://")
      allow(ApplicationConfig).to receive(:[]).with("APP_DOMAIN").and_return("dev.to")
    end

    it "creates the correct base app URL" do
      expect(app_url).to eq("https://dev.to")
    end

    it "creates a URL with a path" do
      expect(app_url("internal")).to eq("https://dev.to/internal")
    end

    it "creates the correct URL even if the path starts with a slash" do
      expect(app_url("/internal")).to eq("https://dev.to/internal")
    end

    it "works when called with an URI object" do
      uri = URI::Generic.build(path: "internal", fragment: "test")
      expect(app_url(uri)).to eq("https://dev.to/internal#test")
    end
  end
end
