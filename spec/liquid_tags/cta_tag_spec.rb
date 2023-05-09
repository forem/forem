require "rails_helper"

RSpec.describe CtaTag, type: :liquid_tag do
  describe "#render" do
    let(:link) { "https://dev.to/" }
    let(:description) { "DEV Community" }

    def generate_details_liquid(options, description)
      Liquid::Template.register_tag("cta", described_class)
      Liquid::Template.parse("{% cta #{options} %} #{description} {% endcta %}")
    end

    it "contains the correct static attributes" do
      rendered = generate_details_liquid(link, description).render

      expect(rendered).to include("class=\"ltag_cta ltag_cta--branded")
      expect(rendered).to include("role=\"button")
    end

    it "generates the correct href attribute" do
      rendered = generate_details_liquid(link, description).render
      expect(rendered).to include("href=\"#{link}")
    end

    it "contains the correct description" do
      rendered = generate_details_liquid(link, description).render
      expect(rendered).to include(description)
    end

    it "limits the description to 128 characters" do
      long_description = "We do not allow for more than hundred and twenty eight characters in the description of " \
                         "the CTA. This is the same as what we allow for article titles."
      rendered = generate_details_liquid(link, long_description).render
      expect(rendered).to include("We do not allow for more than hundred and twenty eight characters in the " \
                                  "description of the CTA. This is the same as what we ...")
      expect(rendered).not_to include("article titles.")
    end

    it "strips all tags from the description" do
      rendered = generate_details_liquid(link, "<div class='crayons'>DEV Community</div>").render
      expect(rendered).to include("DEV Community")
      expect(rendered).not_to include("class='crayons'")
      expect(rendered).not_to include("<div")
      expect(rendered).not_to include("</div>")
    end
  end
end
