require "rails_helper"

RSpec.describe WarpTag, type: :liquid_tag do
  describe "#render" do
    let(:block_id) { "qn0g1CqQnkYjEafPH5HCVT" }
    let(:valid_block_url) { "https://app.warp.dev/block/#{block_id}" }
    let(:valid_embed_url) { "https://app.warp.dev/block/embed/#{block_id}" }
    let(:invalid_url) { "https://example.com/warp" }
    let(:invalid_warp_url) { "https://app.warp.dev/settings" }

    def generate_new_liquid(url)
      Liquid::Template.register_tag("warp", described_class)
      Liquid::Template.parse("{% warp #{url} %}")
    end

    it "accepts valid block URL and rewrites to embed URL" do
      liquid = generate_new_liquid(valid_block_url)
      expect(liquid.render).to include("src=\"https://app.warp.dev/block/embed/#{block_id}\"")
    end

    it "accepts direct embed URL" do
      liquid = generate_new_liquid(valid_embed_url)
      expect(liquid.render).to include("src=\"https://app.warp.dev/block/embed/#{block_id}\"")
    end

    it "renders with correct wrapper class" do
      liquid = generate_new_liquid(valid_block_url)
      expect(liquid.render).to include('<div class="ltag__warp">')
    end

    it "renders iframe with clipboard permissions" do
      liquid = generate_new_liquid(valid_block_url)
      rendered = liquid.render
      expect(rendered).to include('allow="clipboard-read; clipboard-write"')
      expect(rendered).to include('loading="lazy"')
    end

    it "raises an error for invalid URL" do
      expect { generate_new_liquid(invalid_url).render }
        .to raise_error("Invalid Warp URL")
    end

    it "raises an error for non-block Warp URL" do
      expect { generate_new_liquid(invalid_warp_url).render }
        .to raise_error("Invalid Warp URL")
    end
  end

  describe "embed tag integration" do
    let(:url) { "https://app.warp.dev/block/qn0g1CqQnkYjEafPH5HCVT" }

    def generate_embed_liquid(url)
      stub_request(:head, url).to_return(status: 200, body: "", headers: {})
      Liquid::Template.parse("{% embed #{url} %}")
    end

    it "works with embed tag" do
      liquid = generate_embed_liquid(url)
      expect(liquid.render).to include('<div class="ltag__warp">')
    end
  end
end
