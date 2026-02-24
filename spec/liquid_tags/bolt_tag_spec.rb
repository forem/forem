require "rails_helper"

RSpec.describe BoltTag, type: :liquid_tag do
  describe "#render" do
    let(:valid_bolt_host) { "https://my-project.bolt.host" }
    let(:valid_bolt_host_with_slash) { "https://my-project.bolt.host/" }
    let(:valid_bolt_new_project) { "https://bolt.new/~/my-project-slug" }
    let(:invalid_url) { "https://example.com/bolt" }
    let(:invalid_bolt_url) { "https://bolt.new/pricing" }

    def generate_new_liquid(url)
      Liquid::Template.register_tag("bolt", described_class)
      Liquid::Template.parse("{% bolt #{url} %}")
    end

    it "accepts valid bolt.host URL" do
      liquid = generate_new_liquid(valid_bolt_host)
      rendered = liquid.render
      expect(rendered).to include('<div class="ltag__bolt">')
      expect(rendered).to include('src="https://my-project.bolt.host"')
    end

    it "accepts bolt.host with trailing slash" do
      liquid = generate_new_liquid(valid_bolt_host_with_slash)
      expect(liquid.render).to include('src="https://my-project.bolt.host"')
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

    it "raises an error for invalid URL" do
      expect { generate_new_liquid(invalid_url).render }
        .to raise_error("Invalid Bolt URL")
    end

    it "raises an error for non-project Bolt URL" do
      expect { generate_new_liquid(invalid_bolt_url).render }
        .to raise_error("Invalid Bolt URL")
    end
  end

  describe "embed tag integration" do
    let(:url) { "https://my-project.bolt.host" }

    def generate_embed_liquid(url)
      stub_request(:head, url).to_return(status: 200, body: "", headers: {})
      Liquid::Template.parse("{% embed #{url} %}")
    end

    it "works with embed tag" do
      liquid = generate_embed_liquid(url)
      expect(liquid.render).to include('<div class="ltag__bolt">')
    end
  end
end
