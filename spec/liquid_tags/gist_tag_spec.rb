require 'rails_helper'

RSpec.describe GistTag, type: :liquid_template do
  describe "#link" do
    let(:gist_link) { "https://gist.github.com/vaidehijoshi/6536e03b81e93a78c56537117791c3f1" }

    def generate_new_liquid(link)
      Liquid::Template.register_tag("gist", GistTag)
      Liquid::Template.parse("{% gist #{link} %}")
    end

    def generate_script(link)
      html = <<~HTML
        <div class="ltag_gist-liquid-tag">
            <script id="gist-ltag" src="#{link}.js"></script>
        </div>
      HTML
      html.gsub("\n", " ").delete(" ")
    end

    it "accepts proper gist url" do
      liquid = generate_new_liquid(gist_link)
      expect(liquid.render.delete(" ")).to eq(generate_script(gist_link))
    end

    it "rejects invalid gist url" do
      expect {
        generate_new_liquid("really_long_invalid_id")
      }.to raise_error(StandardError)
    end
  end
end
