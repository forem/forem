require "rails_helper"

RSpec.describe V0Tag, type: :liquid_tag do
  describe "#render" do
    let(:valid_vusercontent_url) { "https://abc123def.vusercontent.net" }
    let(:valid_vusercontent_lite) { "https://abc123def.lite.vusercontent.net" }
    let(:valid_vusercontent_path) { "https://generated.vusercontent.net/p/dh2l48aqQPN" }
    let(:valid_v0_chat_url) { "https://v0.dev/chat/my-project-abc123" }

    def generate_new_liquid(url)
      stub_request(:head, url).to_return(status: 200, body: "", headers: {})
      Liquid::Template.parse("{% embed #{url} %}")
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
  end

  describe "UnifiedEmbed registry" do
    it "routes vusercontent.net URLs to V0Tag" do
      handler = UnifiedEmbed::Registry.find_liquid_tag_for(link: "https://abc123.vusercontent.net")
      expect(handler).to eq(described_class)
    end

    it "routes v0.dev/chat URLs to V0Tag" do
      handler = UnifiedEmbed::Registry.find_liquid_tag_for(link: "https://v0.dev/chat/my-project-abc")
      expect(handler).to eq(described_class)
    end

    it "routes generated vusercontent.net path URLs to V0Tag" do
      handler = UnifiedEmbed::Registry.find_liquid_tag_for(link: "https://generated.vusercontent.net/p/dh2l48aqQPN")
      expect(handler).to eq(described_class)
    end
  end

  describe "REGISTRY_REGEXP" do
    it "matches and captures the full vusercontent API path" do
      match = "https://generated.vusercontent.net/p/dh2l48aqQPN".match(V0Tag::REGISTRY_REGEXP)
      expect(match[0]).to eq("https://generated.vusercontent.net/p/dh2l48aqQPN")
    end

    it "matches and captures the base vusercontent URL" do
      match = "https://abc123def.vusercontent.net".match(V0Tag::REGISTRY_REGEXP)
      expect(match[0]).to eq("https://abc123def.vusercontent.net")
    end

    it "matches and captures lite.vusercontent.net URLs" do
      match = "https://abc123def.lite.vusercontent.net".match(V0Tag::REGISTRY_REGEXP)
      expect(match[0]).to eq("https://abc123def.lite.vusercontent.net")
    end

    it "matches and captures v0.dev/chat URLs" do
      match = "https://v0.dev/chat/my-project-abc123".match(V0Tag::REGISTRY_REGEXP)
      expect(match[0]).to eq("https://v0.dev/chat/my-project-abc123")
    end

    it "does not match invalid domains" do
      expect("https://generated.vusercontent.com/p/dh2l48aqQPN").not_to match(V0Tag::REGISTRY_REGEXP)
    end
  end
end
