require "rails_helper"

RSpec.describe LovableTag, type: :liquid_tag do
  describe "#render" do
    let(:valid_url) { "https://my-app.lovable.app" }
    let(:valid_url_with_path) { "https://my-app.lovable.app/dashboard" }

    def generate_new_liquid(url)
      stub_request(:head, url).to_return(status: 200, body: "", headers: {})
      Liquid::Template.parse("{% embed #{url} %}")
    end

    it "accepts valid lovable.app URL" do
      liquid = generate_new_liquid(valid_url)
      rendered = liquid.render
      expect(rendered).to include('<div class="ltag__lovable">')
      expect(rendered).to include('src="https://my-app.lovable.app"')
    end

    it "accepts URL with path" do
      liquid = generate_new_liquid(valid_url_with_path)
      expect(liquid.render).to include('src="https://my-app.lovable.app/dashboard"')
    end

    it "renders iframe with correct attributes" do
      liquid = generate_new_liquid(valid_url)
      rendered = liquid.render
      expect(rendered).to include('height="600"')
      expect(rendered).to include('loading="lazy"')
    end
  end

  describe "UnifiedEmbed registry" do
    it "routes lovable.app URLs to LovableTag" do
      handler = UnifiedEmbed::Registry.find_liquid_tag_for(link: "https://my-app.lovable.app")
      expect(handler).to eq(described_class)
    end
  end
end
