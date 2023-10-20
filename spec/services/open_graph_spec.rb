require "rails_helper"

describe OpenGraph, :vcr, type: :service do
  VCR.use_cassette("open_graph") do
    let(:page) { described_class.new("https://github.com/forem") }
  end

  describe "meta-programmed methods" do
    it "calls the methods" do
      expect(page.title).to eq("Forem · GitHub")
      expect(page.url).to eq("https://github.com/forem")
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

  describe "twitter" do
    it "returns twitter data" do
      expect(page.twitter["twitter:site"]).to eq "@github"
      expect(page.twitter["twitter:title"]).to eq "Forem"
      expect(page.twitter["twitter:card"]).to eq "summary_large_image"
    end

    it "returns empty hash when not available" do
      allow(page).to receive(:twitter).and_return({})

      expect(page.twitter).to be_blank
    end
  end

  describe "grouped by key" do
    it "groups open graph properties" do
      expect(page.grouped_properties).to have_key("fb")
      expect(page.grouped_properties).to have_key("og")
      expect(page.grouped_properties).to have_key("profile")
    end

    # not an exhaustive check but will check a couple of the more popular ones
    # and make sure they're grouped
    it "groups metadata" do
      expect(page.grouped_meta).to have_key("og")
      expect(page.grouped_meta).to have_key("twitter")
      expect(page.grouped_meta["og"].size).to eq 7
      expect(page.grouped_meta["og"].class).to eq Hash
      expect(page.grouped_meta["twitter"].size).to eq 5
      expect(page.grouped_meta["twitter"].class).to eq Hash
    end
  end
end
