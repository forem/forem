require "rails_helper"

RSpec.describe HuggingfaceTag, type: :liquid_tag do
  describe "#render" do
    let(:valid_hf_space_url) { "https://user-name-my-space.hf.space" }
    let(:valid_huggingface_co_url) { "https://huggingface.co/spaces/username/my-space" }
    let(:valid_dataset_url) { "https://huggingface.co/datasets/fka/awesome-chatgpt-prompts" }
    let(:valid_dataset_embed_url) { "https://huggingface.co/datasets/fka/awesome-chatgpt-prompts/embed/viewer" }

    def generate_new_liquid(url)
      stub_request(:head, url).to_return(status: 200, body: "", headers: {})
      Liquid::Template.parse("{% embed #{url} %}")
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

    it "converts huggingface.co/spaces URL to hf.space format" do
      liquid = generate_new_liquid(valid_huggingface_co_url)
      rendered = liquid.render
      expect(rendered).to include('src="https://username-my-space.hf.space"')
    end

    it "accepts dataset URL and converts to embed viewer" do
      liquid = generate_new_liquid(valid_dataset_url)
      rendered = liquid.render
      expect(rendered).to include('src="https://huggingface.co/datasets/fka/awesome-chatgpt-prompts/embed/viewer"')
    end

    it "accepts dataset URL with /embed/viewer already in path" do
      liquid = generate_new_liquid(valid_dataset_embed_url)
      rendered = liquid.render
      expect(rendered).to include('src="https://huggingface.co/datasets/fka/awesome-chatgpt-prompts/embed/viewer"')
    end

    it "renders iframe with correct attributes" do
      liquid = generate_new_liquid(valid_hf_space_url)
      rendered = liquid.render
      expect(rendered).to include('loading="lazy"')
      expect(rendered).to include('height="600"')
    end
  end

  describe "UnifiedEmbed registry" do
    it "routes hf.space URLs to HuggingfaceTag" do
      handler = UnifiedEmbed::Registry.find_liquid_tag_for(link: "https://my-space.hf.space")
      expect(handler).to eq(described_class)
    end

    it "routes huggingface.co/spaces URLs to HuggingfaceTag" do
      handler = UnifiedEmbed::Registry.find_liquid_tag_for(link: "https://huggingface.co/spaces/user/space")
      expect(handler).to eq(described_class)
    end

    it "routes huggingface.co/datasets URLs to HuggingfaceTag" do
      handler = UnifiedEmbed::Registry.find_liquid_tag_for(link: "https://huggingface.co/datasets/fka/awesome-chatgpt-prompts")
      expect(handler).to eq(described_class)
    end
  end
end
