require "rails_helper"

RSpec.describe HuggingfaceTag, type: :liquid_tag do
  describe "#render" do
    let(:valid_hf_space_url) { "https://user-name-my-space.hf.space" }
    let(:valid_hf_space_with_path) { "https://user-name-my-space.hf.space/" }
    let(:valid_huggingface_co_url) { "https://huggingface.co/spaces/username/my-space" }
    let(:valid_huggingface_co_with_trailing) { "https://huggingface.co/spaces/username/my-space/" }
    let(:invalid_url) { "https://example.com/spaces/foo" }
    let(:invalid_hf_url) { "https://huggingface.co/models/username/model" }

    def generate_new_liquid(url)
      Liquid::Template.register_tag("huggingface", described_class)
      Liquid::Template.parse("{% huggingface #{url} %}")
    end

    it "accepts valid hf.space URL" do
      liquid = generate_new_liquid(valid_hf_space_url)
      rendered = liquid.render
      expect(rendered).to include('<div class="ltag__huggingface">')
      expect(rendered).to include('src="https://user-name-my-space.hf.space"')
    end

    it "accepts valid huggingface.co/spaces URL" do
      liquid = generate_new_liquid(valid_huggingface_co_url)
      rendered = liquid.render
      expect(rendered).to include('<div class="ltag__huggingface">')
      expect(rendered).to include("<iframe")
    end

    it "renders iframe with correct attributes" do
      liquid = generate_new_liquid(valid_hf_space_url)
      rendered = liquid.render
      expect(rendered).to include('loading="lazy"')
      expect(rendered).to include('height="600"')
    end

    it "raises an error for invalid URL" do
      expect { generate_new_liquid(invalid_url).render }
        .to raise_error("Invalid Hugging Face Space URL")
    end

    it "raises an error for non-spaces HF URL" do
      expect { generate_new_liquid(invalid_hf_url).render }
        .to raise_error("Invalid Hugging Face Space URL")
    end
  end

  describe "embed tag integration" do
    let(:url) { "https://user-name-my-space.hf.space" }

    def generate_embed_liquid(url)
      stub_request(:head, url).to_return(status: 200, body: "", headers: {})
      Liquid::Template.parse("{% embed #{url} %}")
    end

    it "works with embed tag" do
      liquid = generate_embed_liquid(url)
      expect(liquid.render).to include('<div class="ltag__huggingface">')
    end
  end
end
