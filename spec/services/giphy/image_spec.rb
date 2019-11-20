require "rails_helper"

RSpec.describe Giphy::Image, type: :service do
  describe "self.valid_url?" do
    context "when the URL is not a giphy URL" do
      it "returns false if the URI scheme is not https" do
        url = "http://media.giphy.com/media/H7NQUsEwTGfjkr9QoG/giphy.gif"

        expect(described_class.valid_url?(url)).to be false
      end

      it "returns false if the URI has userinfo" do
        url = "https://username:password@media.giphy.com/media/H7NQUsEwTGfjkr9QoG/giphy.gif"

        expect(described_class.valid_url?(url)).to be false
      end

      it "returns false if the URI has a fragment" do
        url = "https://media.giphy.com/media/H7NQUsEwTGfjkr9QoG/giphy.gif#a-fragment"

        expect(described_class.valid_url?(url)).to be false
      end

      it "returns false if the URI contains query params" do
        url = "https://media.giphy.com/media/H7NQUsEwTGfjkr9QoG/giphy.gif?query_param=1"

        expect(described_class.valid_url?(url)).to be false
      end

      it "returns false if the host is not a subdomain of giphy.com" do
        url = "https://example.com/some_url"

        expect(described_class.valid_url?(url)).to be false
      end
    end

    context "when the URI host is giphy.com and it ends with .gif" do
      it "returns true if the URI host is media.giphy.com" do
        url = "https://media.giphy.com/media/H7NQUsEwTGfjkr9QoG/giphy.gif"

        expect(described_class.valid_url?(url)).to be true
      end

      it "returns true if the URI host is i.giphy.com" do
        url = "https://i.giphy.com/l0O9xQNSsQKmfSeUU.gif"

        expect(described_class.valid_url?(url)).to be true
      end
    end

    context "when the URI host is giphy.com and it does not end with .gif" do
      it "returns false" do
        url = "https://i.giphy.com/l0O9xQNSsQKmfSeUU"

        expect(described_class.valid_url?(url)).to be false
      end
    end
  end
end
