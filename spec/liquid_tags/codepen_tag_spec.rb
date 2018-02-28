require "rails_helper"

RSpec.describe CodepenTag, type: :liquid_template do
  describe "#link" do
    let(:codepen_link) { "https://codepen.io/twhite96/pen/XKqrJX" }

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
  end
end
