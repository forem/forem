require "rails_helper"

RSpec.describe WikipediaTag, type: :liquid_tag, vcr: true do
  describe "#id" do
    let(:valid_url) { "https://en.wikipedia.org/wiki/Wikipedia" }
    let(:valid_section_url) { "https://en.wikipedia.org/wiki/Wikipedia#Diversity" }
    let(:invalid_url) { "https://123.wikipedia.org/wiki/Wiki" }

    def generate_new_liquid(url)
      Liquid::Template.register_tag("wikipedia", WikipediaTag)
      Liquid::Template.parse("{% wikipedia #{url} %}")
    end

    it "renders wikipedia excerpt html" do
      VCR.use_cassette("wikipedia_tag") do
        liquid = generate_new_liquid(valid_url)
        expect(liquid.render).to include("ltag__wikipedia")
          .and include("<b>Wikipedia</b> is a multilingual online encyclopedia")
      end
    end

    it "renders wikipedia article section html" do
      VCR.use_cassette("wikipedia_section_tag") do
        liquid = generate_new_liquid(valid_section_url)
        expect(liquid.render).to include("ltag__wikipedia")
          .and include("Several studies have shown that most of the Wikipedia contributors are male.")
      end
    end

    it "rejects invalid url" do
      expect do
        liquid = generate_new_liquid(invalid_url)
        liquid.render
      end.to raise_error(StandardError)
    end
  end
end
