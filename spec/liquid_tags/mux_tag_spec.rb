require "rails_helper"

RSpec.describe MuxTag, type: :liquid_tag do
  subject(:mux_tag) { described_class }

  let(:article) { create(:article) }
  let(:user) { create(:user) }
  let(:parse_context) { { source: article, user: user } }
  let(:mux_url) { "https://player.mux.com/nw5QrgIQS02FEx5BJEQH8CdcLmXXRvCNACZKQ01kLoKEI" }
  let(:mux_url_with_query) { "https://player.mux.com/nw5QrgIQS02FEx5BJEQH8CdcLmXXRvCNACZKQ01kLoKEI?autoplay=true" }
  let(:expected_video_id) { "nw5QrgIQS02FEx5BJEQH8CdcLmXXRvCNACZKQ01kLoKEI" }

  let(:registry_regexp) do
    %r{https://player\.mux\.com/(?<video_id>[a-zA-Z0-9_-]+)(?:\?[\w=&-]+)?$}
  end

  def generate_embed(url)
    UnifiedEmbed.register(described_class, regexp: registry_regexp, skip_validation: true)
    Liquid::Template.parse("{% embed #{url} %}")
  end

  describe "rendering" do
    it "returns Mux embed for valid Mux player URL" do
      embed = generate_embed(mux_url).render

      expect(embed).to include("<iframe")
      expect(embed).to include("src=\"https://player.mux.com/#{expected_video_id}\"")
      expect(embed).to include("width=\"710\"")
      expect(embed).to include("height=\"399\"")
      expect(embed).to include("allowfullscreen")
      expect(embed).to include("loading=\"lazy\"")
    end

    it "returns Mux embed for valid Mux player URL with query parameters" do
      embed = generate_embed(mux_url_with_query).render

      expect(embed).to include("<iframe")
      expect(embed).to include("src=\"https://player.mux.com/#{expected_video_id}\"")
    end

    it "handles different video ID formats" do
      # Test with a shorter video ID
      short_id_url = "https://player.mux.com/abc123"
      embed = generate_embed(short_id_url).render
      expect(embed).to include("src=\"https://player.mux.com/abc123\"")
    end

    it "extracts video ID correctly from URL through rendering" do
      embed = generate_embed(mux_url).render
      expect(embed).to include("src=\"https://player.mux.com/#{expected_video_id}\"")
    end

    it "handles URLs with query parameters through rendering" do
      embed = generate_embed(mux_url_with_query).render
      expect(embed).to include("src=\"https://player.mux.com/#{expected_video_id}\"")
    end
  end

  describe "UnifiedEmbed integration" do
    it "is registered with UnifiedEmbed" do
      handler = UnifiedEmbed::Registry.find_handler_for(link: mux_url)
      expect(handler).not_to be_nil
      expect(handler[:klass]).to eq(MuxTag)
      expect(handler[:skip_validation]).to be true
    end

    it "works with embed tag syntax" do
      embed = generate_embed(mux_url).render
      expect(embed).to include("<iframe")
      expect(embed).to include("player.mux.com")
    end

    it "does not match non-Mux URLs" do
      handler = UnifiedEmbed::Registry.find_handler_for(link: "https://youtube.com/watch?v=123")
      expect(handler).to be_nil unless handler&.dig(:klass) != MuxTag
    end
  end
end

