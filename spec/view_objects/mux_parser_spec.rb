require "rails_helper"

RSpec.describe MuxParser do
  describe "#call" do
    context "with valid Mux player URL" do
      let(:valid_url) { "https://player.mux.com/nw5QrgIQS02FEx5BJEQH8CdcLmXXRvCNACZKQ01kLoKEI" }
      let(:expected_embed_url) { "https://player.mux.com/nw5QrgIQS02FEx5BJEQH8CdcLmXXRvCNACZKQ01kLoKEI" }

      it "returns the embed URL" do
        parser = described_class.new(valid_url)
        expect(parser.call).to eq(expected_embed_url)
      end

      it "extracts the video ID correctly" do
        parser = described_class.new(valid_url)
        expect(parser.video_id).to eq("nw5QrgIQS02FEx5BJEQH8CdcLmXXRvCNACZKQ01kLoKEI")
      end
    end

    context "with Mux URL with query parameters" do
      let(:url_with_params) { "https://player.mux.com/nw5QrgIQS02FEx5BJEQH8CdcLmXXRvCNACZKQ01kLoKEI?autoplay=true" }
      let(:expected_embed_url) { "https://player.mux.com/nw5QrgIQS02FEx5BJEQH8CdcLmXXRvCNACZKQ01kLoKEI" }

      it "returns the embed URL without query parameters" do
        parser = described_class.new(url_with_params)
        expect(parser.call).to eq(expected_embed_url)
      end

      it "extracts the video ID correctly" do
        parser = described_class.new(url_with_params)
        expect(parser.video_id).to eq("nw5QrgIQS02FEx5BJEQH8CdcLmXXRvCNACZKQ01kLoKEI")
      end
    end

    context "with invalid URLs" do
      it "returns nil for non-Mux URLs" do
        parser = described_class.new("https://youtube.com/watch?v=123")
        expect(parser.call).to be_nil
      end

      it "returns nil for empty string" do
        parser = described_class.new("")
        expect(parser.call).to be_nil
      end

      it "returns nil for invalid URL format" do
        parser = described_class.new("not-a-url")
        expect(parser.call).to be_nil
      end

      it "returns nil for Mux URL without video ID" do
        parser = described_class.new("https://player.mux.com/")
        expect(parser.call).to be_nil
      end

      it "returns nil for different Mux domain" do
        parser = described_class.new("https://mux.com/video/123")
        expect(parser.call).to be_nil
      end
    end

    context "with different video ID formats" do
      it "handles short video IDs" do
        parser = described_class.new("https://player.mux.com/abc123")
        expect(parser.call).to eq("https://player.mux.com/abc123")
        expect(parser.video_id).to eq("abc123")
      end

      it "handles video IDs with dashes and underscores" do
        parser = described_class.new("https://player.mux.com/video-id_with_underscore")
        expect(parser.call).to eq("https://player.mux.com/video-id_with_underscore")
        expect(parser.video_id).to eq("video-id_with_underscore")
      end
    end
  end
end

