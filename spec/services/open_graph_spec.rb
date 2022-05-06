require "rails_helper"

describe OpenGraph, type: :service, vcr: true do
  VCR.use_cassette("open_graph") do
    let(:page) { described_class.new("https://github.com/forem") }
  end

  describe "meta-programmed methods" do
    it "calls the methods" do
      expect(page.title).to eq("Forem")
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

  describe ".main_properties_present?" do
    let(:page_with_missing_description) do
      <<-HTML
        <html>
          <head>
            <title>Some Title</title>
          </head>
          <body>Some Content</body>
        </html>
      HTML
    end

    it "returns true if the main properties are all present" do
      expect(page.main_properties_present?).to be(true)
    end

    it "returns false if any main property is not present" do
      allow(Net::HTTP).to receive(:get).and_return(page_with_missing_description)

      expect(page.main_properties_present?).to be(false)
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

  describe ".description" do
    let(:page_with_og_description) do
      <<-HTML
        <html>
          <head>
            <title>Some Title</title>
            <description>Generic Description</description>
            <meta property="og:description" content="Open Graph Description.">
            <meta property="twitter:description" content="Twitter Description.">
          </head>
          <body>Some Content</body>
        </html>
      HTML
    end

    let(:page_without_og_and_with_twitter_description) do
      <<-HTML
        <html>
          <head>
            <title>Some Title</title>
            <description>Generic Description</description>
            <meta property="twitter:description" content="Twitter Description.">
          </head>
          <body>Some Content</body>
        </html>
      HTML
    end

    let(:page_without_og_or_twitter_description) do
      <<-HTML
        <html>
          <head>
            <title>Some Title</title>
            <meta property="description" content="Generic Description.">
          </head>
          <body>Some Content</body>
        </html>
      HTML
    end

    it "returns the open graph meta value if present" do
      allow(Net::HTTP).to receive(:get).and_return(page_with_og_description)

      expect(page.get_preferred_meta_value("description")).to eq("Open Graph Description.")
    end

    it "returns the twitter meta value if open graph meta value is not present" do
      allow(Net::HTTP).to receive(:get).and_return(page_without_og_and_with_twitter_description)

      expect(page.get_preferred_meta_value("description")).to eq("Twitter Description.")
    end

    it "returns the description meta value if both open graph and twitter meta values are not present" do
      allow(Net::HTTP).to receive(:get).and_return(page_without_og_or_twitter_description)

      expect(page.get_preferred_meta_value("description")).to eq("Generic Description.")
    end
  end

  describe ".title" do
    let(:page_with_og_title) do
      <<-HTML
        <html>
          <head>
            <title>Some Title</title>
            <meta property="og:title" content="Open Graph Title">
            <meta property="twitter:title" content="Twitter Title">
          </head>
          <body>Some Content</body>
        </html>
      HTML
    end

    let(:page_without_og_and_with_twitter_title) do
      <<-HTML
        <html>
          <head>
            <title>Some Title</title>
            <meta property="twitter:title" content="Twitter Title">
          </head>
          <body>Some Content</body>
        </html>
      HTML
    end

    let(:page_without_og_or_twitter_title) do
      <<-HTML
        <html>
          <head>
            <title>Some Title</title>
          </head>
          <body>Some Content</body>
        </html>
      HTML
    end

    it "returns the open graph meta value if present" do
      allow(Net::HTTP).to receive(:get).and_return(page_with_og_title)

      expect(page.get_preferred_meta_value("title")).to eq("Open Graph Title")
    end

    it "returns the twitter meta value if open graph meta value is not present" do
      allow(Net::HTTP).to receive(:get).and_return(page_without_og_and_with_twitter_title)

      expect(page.get_preferred_meta_value("title")).to eq("Twitter Title")
    end

    it "returns the title meta value if both open graph and twitter meta values are not present" do
      allow(Net::HTTP).to receive(:get).and_return(page_without_og_or_twitter_title)

      expect(page.get_preferred_meta_value("title")).to eq("Some Title")
    end
  end
end
