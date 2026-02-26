require "rails_helper"

RSpec.describe BoltTag, type: :liquid_tag do
  describe "#render" do
    let(:valid_bolt_host) { "https://my-project.bolt.host" }
    let(:valid_bolt_new_project) { "https://bolt.new/~/my-project-slug" }

    def generate_new_liquid(url)
      stub_request(:head, url).to_return(status: 200, body: "", headers: {})
      Liquid::Template.parse("{% embed #{url} %}")
    end

    it "accepts valid bolt.host URL" do
      liquid = generate_new_liquid(valid_bolt_host)
      rendered = liquid.render
      expect(rendered).to include('<div class="ltag__bolt">')
      expect(rendered).to include('src="https://my-project.bolt.host"')
    end

    it "accepts bolt.new project URL" do
      liquid = generate_new_liquid(valid_bolt_new_project)
      rendered = liquid.render
      expect(rendered).to include('<div class="ltag__bolt">')
      expect(rendered).to include('src="https://bolt.new/~/my-project-slug"')
    end

    it "renders iframe with correct attributes" do
      liquid = generate_new_liquid(valid_bolt_host)
      rendered = liquid.render
      expect(rendered).to include('height="600"')
      expect(rendered).to include('loading="lazy"')
    end
  end

  describe "UnifiedEmbed registry" do
    it "routes bolt.host URLs to BoltTag" do
      handler = UnifiedEmbed::Registry.find_liquid_tag_for(link: "https://project.bolt.host")
      expect(handler).to eq(described_class)
    end

    it "routes bolt.new URLs to BoltTag" do
      handler = UnifiedEmbed::Registry.find_liquid_tag_for(link: "https://bolt.new/~/my-project")
      expect(handler).to eq(described_class)
    end
  end
end
