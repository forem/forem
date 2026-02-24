require "rails_helper"

RSpec.describe StreamlitTag, type: :liquid_tag do
  describe "#render" do
    let(:valid_url) { "https://my-app.streamlit.app" }
    let(:valid_url_with_slash) { "https://my-app.streamlit.app/" }
    let(:valid_url_with_path) { "https://my-app.streamlit.app/some-page" }
    let(:invalid_url) { "https://example.com/streamlit" }
    let(:invalid_format) { "not-a-url" }

    def generate_new_liquid(url)
      Liquid::Template.register_tag("streamlit", described_class)
      Liquid::Template.parse("{% streamlit #{url} %}")
    end

    it "accepts valid Streamlit URL and appends embed param" do
      liquid = generate_new_liquid(valid_url)
      expect(liquid.render).to include('src="https://my-app.streamlit.app?embed=true"')
    end

    it "accepts URL with trailing slash" do
      liquid = generate_new_liquid(valid_url_with_slash)
      expect(liquid.render).to include('src="https://my-app.streamlit.app?embed=true"')
    end

    it "accepts URL with path" do
      liquid = generate_new_liquid(valid_url_with_path)
      expect(liquid.render).to include('src="https://my-app.streamlit.app/some-page?embed=true"')
    end

    it "renders with correct wrapper class" do
      liquid = generate_new_liquid(valid_url)
      expect(liquid.render).to include('<div class="ltag__streamlit">')
    end

    it "renders iframe with correct attributes" do
      liquid = generate_new_liquid(valid_url)
      rendered = liquid.render
      expect(rendered).to include('height="600"')
      expect(rendered).to include('loading="lazy"')
    end

    it "raises an error for invalid URL" do
      expect { generate_new_liquid(invalid_url).render }
        .to raise_error("Invalid Streamlit URL")
    end
  end

  describe "embed tag integration" do
    let(:url) { "https://my-app.streamlit.app" }

    def generate_embed_liquid(url)
      stub_request(:head, url).to_return(status: 200, body: "", headers: {})
      Liquid::Template.parse("{% embed #{url} %}")
    end

    it "works with embed tag" do
      liquid = generate_embed_liquid(url)
      expect(liquid.render).to include('<div class="ltag__streamlit">')
    end
  end
end
