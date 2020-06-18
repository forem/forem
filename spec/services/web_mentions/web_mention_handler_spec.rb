require "rails_helper"

RSpec.describe WebMentions::WebMentionHandler, type: :service do
  let(:canonical_url) { "http://example.com" }
  let(:webmention_url) { "http://example.com/webmention" }
  let(:article_url) { "http://example.com/article" }
  let(:url_without_webmention_support) { stub_request(:get, canonical_url).to_return(status: 200) }
  let(:url_with_relative_path) do
    stub_request(:get, canonical_url).
      to_return(status: 200, body:
      '<html lang="en">
        <head>
          <link href="/webmention" rel="webmention">
        </head>
        <body>
        </body>
      </html>')
  end
  let(:url_with_webmention_support) do
    stub_request(:get, canonical_url).
      to_return(status: 200, body:
      '<html lang="en">
        <head>
          <link href="http://example.com/webmention" rel="webmention">
        </head>
        <body>
        </body>
      </html>')
  end

  before { allow(described_class.new(canonical_url)).to receive(:accepts_webmention?) }

  describe "webmentions handler" do
    context "when checking webmention support" do
      it "returns false on urls without webmention support" do
        url_without_webmention_support
        expect(described_class.new(canonical_url).accepts_webmention?).to be false
      end

      it "returns false on urls with relative webmention url" do
        url_with_relative_path
        expect(described_class.new(canonical_url).accepts_webmention?).to be false
      end

      it "returns true on urls that supports webmention" do
        url_with_webmention_support
        expect(described_class.new(canonical_url).accepts_webmention?).to be true
      end
    end

    context "when sending webmentions" do
      it "sends a post request to the webmention url" do
        allow(RestClient).to receive(:post)

        described_class.new(canonical_url, article_url).send(:send_webmention, webmention_url)
        expect(RestClient).to have_received(:post).
          with(webmention_url, { "source": article_url, "target": canonical_url })
      end
    end
  end
end
