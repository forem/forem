require "rails_helper"

describe OpenGraph, type: :service, vcr: true do
  VCR.use_cassette("open_graph") do
    let(:page) { described_class.new("https://github.com/forem") }
  end

  describe "meta-programmed methods" do
    it "calls the methods" do
      expect(page.title).to eq("Forem · GitHub")
      expect(page.author).to be_nil
      expect(page.description).to include("Forem has 18 repositories available. Follow their code on GitHub.")
    end
  end

  describe ".meta_for" do
    it "gets a specific meta value" do
      expect(page.meta_for("twitter:card")).to eq("summary_large_image")
      expect(page.meta_for("enabled-features")).to eq("MARKETPLACE_PENDING_INSTALLATIONS")
      expect(page.meta_for("theme-color")).to eq("#1e2327")
    end
  end
end
