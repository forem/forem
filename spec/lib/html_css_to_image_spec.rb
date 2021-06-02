require "rails_helper"

RSpec.describe HtmlCssToImage, type: :lib do
  describe ".url" do
    it "returns the url to the created image" do
      stub_request(:post, /hcti.io/)
        .to_return(status: 200,
                   body: '{ "url": "https://hcti.io/v1/image/6c52de9d-4d37-4008-80f8-67155589e1a1" }',
                   headers: { "Content-Type" => "application/json" })

      expect(described_class.url(html: "test")).to eq("https://hcti.io/v1/image/6c52de9d-4d37-4008-80f8-67155589e1a1")
    end

    it "returns fallback image if the request fails" do
      stub_request(:post, /hcti.io/)
        .to_return(status: 429,
                   body: '{ "error": "Plan limit exceeded" }',
                   headers: { "Content-Type" => "application/json" })

      expect(described_class.url(html: "test")).to eq described_class.fallback_image
    end
  end

  describe ".fetch_url" do
    before do
      allow(Settings::General).to receive(:main_social_image).and_return("https://testimage.com/image.png")
      allow(Rails.cache).to receive(:write)
      allow(Rails.cache).to receive(:read)
    end

    it "caches the image url when successful" do
      stub_request(:post, /hcti.io/)
        .to_return(status: 200,
                   body: '{ "url": "https://hcti.io/v1/image/6c52de9d-4d37-4008-80f8-67155589e1a1" }',
                   headers: { "Content-Type" => "application/json" })

      expected_url = "https://hcti.io/v1/image/6c52de9d-4d37-4008-80f8-67155589e1a1"
      expect(described_class.fetch_url(html: "test")).to eq(expected_url)
      expect(Rails.cache).to have_received(:write).once
    end

    it "cache has a long expiration" do
      # Images are expensive to generate, make sure we don't expire them too quickly.
      stub_request(:post, /hcti.io/)
        .to_return(status: 200,
                   body: '{ "url": "https://hcti.io/v1/image/6c52de9d-4d37-4008-80f8-67155589e1a1" }',
                   headers: { "Content-Type" => "application/json" })

      expected_url = "https://hcti.io/v1/image/6c52de9d-4d37-4008-80f8-67155589e1a1"
      expect(described_class.fetch_url(html: "test")).to eq(expected_url)
      expect(Rails.cache).to have_received(:write)
        .with(anything, anything, expires_in: HtmlCssToImage::CACHE_EXPIRATION).once
    end

    it "does not cache errors" do
      stub_request(:post, /hcti.io/)
        .to_return(status: 429,
                   body: '{ "error": "Plan limit exceeded" }',
                   headers: { "Content-Type" => "application/json" })

      expect(described_class.fetch_url(html: "test")).to eq described_class.fallback_image
      expect(Rails.cache).not_to have_received(:write)
    end
  end
end
