require "rails_helper"

RSpec.describe V0Tag, type: :liquid_tag do
  describe "#render" do
    let(:valid_vusercontent_url) { "https://abc123def.vusercontent.net" }
    let(:valid_vusercontent_lite) { "https://abc123def.lite.vusercontent.net" }
    let(:valid_vusercontent_path) { "https://generated.vusercontent.net/p/dh2l48aqQPN" }
    let(:valid_v0_chat_url) { "https://v0.dev/chat/my-project-abc123" }
    let(:invalid_url) { "https://example.com/v0" }
    let(:invalid_v0_url) { "https://v0.dev/pricing" }

    def generate_new_liquid(url)
      Liquid::Template.register_tag("v0", described_class)
      Liquid::Template.parse("{% v0 #{url} %}")
    end

    it "accepts valid vusercontent.net URL" do
      liquid = generate_new_liquid(valid_vusercontent_url)
      rendered = liquid.render
      expect(rendered).to include('<div class="ltag__v0">')
      expect(rendered).to include('src="https://abc123def.vusercontent.net"')
    end

    it "accepts valid lite.vusercontent.net URL" do
      liquid = generate_new_liquid(valid_vusercontent_lite)
      rendered = liquid.render
      expect(rendered).to include('src="https://abc123def.lite.vusercontent.net"')
    end

    it "accepts valid vusercontent.net URL with path" do
      liquid = generate_new_liquid(valid_vusercontent_path)
      rendered = liquid.render
      expect(rendered).to include('src="https://generated.vusercontent.net/p/dh2l48aqQPN"')
    end

    it "accepts valid v0.dev/chat URL" do
      liquid = generate_new_liquid(valid_v0_chat_url)
      rendered = liquid.render
      expect(rendered).to include('src="https://v0.dev/chat/my-project-abc123"')
    end

    it "renders iframe with correct attributes" do
      liquid = generate_new_liquid(valid_vusercontent_url)
      rendered = liquid.render
      expect(rendered).to include('height="600"')
      expect(rendered).to include('loading="lazy"')
    end

    it "raises an error for invalid URL" do
      expect { generate_new_liquid(invalid_url).render }
        .to raise_error("Invalid v0 URL")
    end

    it "raises an error for non-chat v0 URL" do
      expect { generate_new_liquid(invalid_v0_url).render }
        .to raise_error("Invalid v0 URL")
    end
  end

  describe "embed tag integration" do
    let(:url) { "https://abc123def.vusercontent.net" }

    def generate_embed_liquid(url)
      stub_request(:head, url).to_return(status: 200, body: "", headers: {})
      Liquid::Template.parse("{% embed #{url} %}")
    end

    it "works with embed tag" do
      liquid = generate_embed_liquid(url)
      expect(liquid.render).to include('<div class="ltag__v0">')
    end
  end
end
