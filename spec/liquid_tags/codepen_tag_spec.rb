require "rails_helper"

RSpec.describe CodepenTag, type: :liquid_template do
  describe "#link" do
    let(:codepen_link) { "https://codepen.io/twhite96/pen/XKqrJX" }

    xss_links = %w(
      //evil.com/?codepen.io
      https://codepen.io.evil.com
      https://codepen.io/some_username/pen/" onload='alert("xss")'
    )

    def generate_new_liquid(link)
      Liquid::Template.register_tag("codepen", CodepenTag)
      Liquid::Template.parse("{% codepen #{link} %}")
    end

    it "accepts codepen link" do
      liquid = generate_new_liquid(codepen_link)
      rendered_codepen_iframe = liquid.render
      Approvals.verify(rendered_codepen_iframe, name: "codepen_liquid_tag", format: :html)
    end

    it "rejects invalid codepen link" do
      expect do
        generate_new_liquid("invalid_codepen_link")
      end.to raise_error(StandardError)
    end

    it "rejects XSS attempts" do
      xss_links.each do |link|
        expect { generate_new_liquid(link) }.to raise_error(StandardError)
      end
    end
  end
end
