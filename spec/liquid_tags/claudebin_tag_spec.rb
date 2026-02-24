require "rails_helper"

RSpec.describe ClaudebinTag, type: :liquid_tag do
  describe "#render" do
    let(:valid_url) { "https://claudebin.com/threads/nmjOkHsi9G" }
    let(:valid_url_trailing_slash) { "https://claudebin.com/threads/nmjOkHsi9G/" }
    let(:invalid_url) { "https://example.com/threads/abc123" }
    let(:invalid_domain) { "https://claudebin.io/threads/abc123" }
    let(:invalid_path) { "https://claudebin.com/embed/abc123" }

    def generate_new_liquid(url)
      Liquid::Template.register_tag("claudebin", described_class)
      Liquid::Template.parse("{% claudebin #{url} %}")
    end

    it "accepts valid Claudebin thread URL" do
      liquid = generate_new_liquid(valid_url)
      rendered = liquid.render
      expect(rendered).to include('src="https://claudebin.com/threads/nmjOkHsi9G"')
    end

    it "accepts valid URL with trailing slash" do
      liquid = generate_new_liquid(valid_url_trailing_slash)
      rendered = liquid.render
      expect(rendered).to include('src="https://claudebin.com/threads/nmjOkHsi9G"')
    end

    it "renders with correct wrapper class" do
      liquid = generate_new_liquid(valid_url)
      expect(liquid.render).to include('<div class="ltag__claudebin">')
    end

    it "renders iframe with correct attributes" do
      liquid = generate_new_liquid(valid_url)
      rendered = liquid.render
      expect(rendered).to include('height="600"')
      expect(rendered).to include('loading="lazy"')
    end

    it "raises an error for invalid URL" do
      expect { generate_new_liquid(invalid_url).render }
        .to raise_error("Invalid Claudebin URL")
    end

    it "raises an error for wrong domain" do
      expect { generate_new_liquid(invalid_domain).render }
        .to raise_error("Invalid Claudebin URL")
    end

    it "raises an error for invalid path" do
      expect { generate_new_liquid(invalid_path).render }
        .to raise_error("Invalid Claudebin URL")
    end
  end

  describe "embed tag integration" do
    let(:url) { "https://claudebin.com/threads/nmjOkHsi9G" }

    def generate_embed_liquid(url)
      stub_request(:head, url).to_return(status: 200, body: "", headers: {})
      Liquid::Template.parse("{% embed #{url} %}")
    end

    it "works with embed tag" do
      liquid = generate_embed_liquid(url)
      expect(liquid.render).to include('<div class="ltag__claudebin">')
    end
  end
end
