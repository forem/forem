require "rails_helper"

RSpec.describe URL, type: :lib do
  before do
    allow(ApplicationConfig).to receive(:[]).with("APP_PROTOCOL").and_return("https://")
    allow(ApplicationConfig).to receive(:[]).with("APP_DOMAIN").and_return("dev.to")
  end

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

  describe ".article" do
    let(:article) { build(:article, path: "/username1/slug") }

    it "returns the correct URL for an article" do
      expect(described_class.article(article)).to eq("https://dev.to#{article.path}")
    end
  end

  describe ".user" do
    let(:user) { build(:user) }

    it "returns the correct URL for a user" do
      expect(described_class.user(user)).to eq("https://dev.to/#{user.username}")
    end
  end

  describe ".tag" do
    let(:tag) { build(:tag) }

    it "returns the correct URL for a tag with no page" do
      expect(described_class.tag(tag)).to eq("https://dev.to/t/#{tag.name}")
    end

    it "returns the correct URL for a tag" do
      expect(described_class.tag(tag, 2)).to eq("https://dev.to/t/#{tag.name}/page/2")
    end
  end
end
