require "rails_helper"

RSpec.describe ClaudeArtifactTag, type: :liquid_tag do
  describe "#render" do
    let(:uuid) { "192abf2c-315d-4938-ae6c-6125157e44f0" }
    let(:valid_url) { "https://claude.site/artifacts/#{uuid}" }
    let(:valid_url_with_path) { "https://claude.site/artifacts/#{uuid}/" }
    let(:valid_public_embed_url) { "https://claude.site/public/artifacts/#{uuid}/embed" }
    let(:invalid_url) { "https://example.com/artifacts/123" }
    let(:invalid_domain) { "https://claude.ai/artifacts/#{uuid}" }
    let(:invalid_no_uuid) { "https://claude.site/artifacts/" }

    def generate_new_liquid(url)
      Liquid::Template.register_tag("claudeartifact", described_class)
      Liquid::Template.parse("{% claudeartifact #{url} %}")
    end

    it "accepts valid Claude Artifact URL and rewrites to embed URL" do
      liquid = generate_new_liquid(valid_url)
      expect(liquid.render).to include('src="https://claude.site/public/artifacts/192abf2c-315d-4938-ae6c-6125157e44f0/embed"')
    end

    it "accepts valid URL with trailing slash" do
      liquid = generate_new_liquid(valid_url_with_path)
      expect(liquid.render).to include('src="https://claude.site/public/artifacts/192abf2c-315d-4938-ae6c-6125157e44f0/embed"')
    end

    it "accepts direct public embed URL" do
      liquid = generate_new_liquid(valid_public_embed_url)
      expect(liquid.render).to include('src="https://claude.site/public/artifacts/192abf2c-315d-4938-ae6c-6125157e44f0/embed"')
    end

    it "renders with correct wrapper class" do
      liquid = generate_new_liquid(valid_url)
      expect(liquid.render).to include('<div class="ltag__claude-artifact">')
    end

    it "renders iframe with clipboard-write permission" do
      liquid = generate_new_liquid(valid_url)
      rendered = liquid.render
      expect(rendered).to include('allow="clipboard-write"')
      expect(rendered).to include("allowfullscreen")
      expect(rendered).to include('loading="lazy"')
    end

    it "raises an error for invalid URL" do
      expect { generate_new_liquid(invalid_url).render }
        .to raise_error("Invalid Claude Artifact URL")
    end

    it "raises an error for wrong domain" do
      expect { generate_new_liquid(invalid_domain).render }
        .to raise_error("Invalid Claude Artifact URL")
    end

    it "raises an error for missing UUID" do
      expect { generate_new_liquid(invalid_no_uuid).render }
        .to raise_error("Invalid Claude Artifact URL")
    end
  end

  describe "embed tag integration" do
    let(:url) { "https://claude.site/artifacts/192abf2c-315d-4938-ae6c-6125157e44f0" }

    def generate_embed_liquid(url)
      stub_request(:head, url).to_return(status: 200, body: "", headers: {})
      Liquid::Template.parse("{% embed #{url} %}")
    end

    it "works with embed tag" do
      liquid = generate_embed_liquid(url)
      expect(liquid.render).to include('<div class="ltag__claude-artifact">')
    end
  end
end
