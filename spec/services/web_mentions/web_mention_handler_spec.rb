require "rails_helper"

RSpec.describe WebMentions::WebMentionHandler, type: :service do
  let(:canonical_url) { "http://example.com" }
  let(:webmention_url) { "http://example.com/webmention" }
  let(:article_url) { "http://example.com/article" }
  let(:url_without_webmention_support) { stub_request(:get, canonical_url).to_return(status: 200) }

  before { allow(described_class.new(canonical_url)).to receive(:call) }

  describe "webmentions handler" do
    context "when checking webmention support" do
      it "returns false on urls without webmention support" do
        url_without_webmention_support
        expect(described_class.new(canonical_url).call).to be_falsey
      end
    end

    context "when sending webmentions" do
      it "sends a post request to the webmention url" do
        allow(HTTParty).to receive(:post)

        described_class.new(canonical_url, article_url, webmention_url).__send__(:send_webmention)
        expect(HTTParty).to have_received(:post)
          .with(webmention_url, { "source": article_url, "target": canonical_url })
      end
    end
  end
end
