require "rails_helper"

RSpec.describe HtmlCssToImage do
  describe ".url" do
    it "returns the url to the created image" do
      stub_request(:post, /hcti.io/).
        to_return(status: 200,
                  body: '{ "url": "https://hcti.io/v1/image/6c52de9d-4d37-4008-80f8-67155589e1a1" }',
                  headers: { "Content-Type" => "application/json" })

      expect(described_class.url(html: "test")).to eq("https://hcti.io/v1/image/6c52de9d-4d37-4008-80f8-67155589e1a1")
    end

    it "returns fallback image if the request fails" do
      stub_request(:post, /hcti.io/).
        to_return(status: 429,
                  body: '{ "error": "Plan limit exceeded" }',
                  headers: { "Content-Type" => "application/json" })

      expect(described_class.url(html: "test")).to eq described_class::FALLBACK_IMAGE
    end
  end

  describe ".fetch_url" do
    before do
      allow(RedisClient).to receive(:get)
      allow(RedisClient).to receive(:set)
    end

    it "caches the image url when successful" do
      stub_request(:post, /hcti.io/).
        to_return(status: 200,
                  body: '{ "url": "https://hcti.io/v1/image/6c52de9d-4d37-4008-80f8-67155589e1a1" }',
                  headers: { "Content-Type" => "application/json" })

      expect(described_class.fetch_url(html: "test")).to eq("https://hcti.io/v1/image/6c52de9d-4d37-4008-80f8-67155589e1a1")
      expect(RedisClient).to have_received(:set).once
    end

    it "does not cache errors" do
      stub_request(:post, /hcti.io/).
        to_return(status: 429,
                  body: '{ "error": "Plan limit exceeded" }',
                  headers: { "Content-Type" => "application/json" })

      expect(described_class.fetch_url(html: "test")).to eq described_class::FALLBACK_IMAGE
      expect(RedisClient).not_to have_received(:set)
    end
  end
end
