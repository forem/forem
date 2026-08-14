require "rails_helper"

RSpec.describe WarpTag, type: :liquid_tag do
  describe "#render" do
    let(:block_id) { "qn0g1CqQnkYjEafPH5HCVT" }
    let(:valid_block_url) { "https://app.warp.dev/block/#{block_id}" }
    let(:valid_embed_url) { "https://app.warp.dev/block/embed/#{block_id}" }

    def generate_new_liquid(url)
      stub_request(:head, url).to_return(status: 200, body: "", headers: {})
      Liquid::Template.parse("{% embed #{url} %}")
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
  end

  describe "UnifiedEmbed registry" do
    it "routes warp.dev block URLs to WarpTag" do
      handler = UnifiedEmbed::Registry.find_liquid_tag_for(link: "https://app.warp.dev/block/abc123")
      expect(handler).to eq(described_class)
    end
  end
end
