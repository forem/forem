require "rails_helper"

RSpec.describe CtaTag, type: :liquid_tag do
  describe "#render" do
    let(:link) { "https://dev.to/" }
    let(:description) { "DEV Community" }

    # test case where no link provided
    # do we want to account for alignment

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

    xit "limits the description to 128 characters" do
      expect do
        generate_details_liquid(link, "We do not allow for more than hundred and twenty eight characters
          in the description of the CTA. This is the same as what we allow for article titles.").render
      end.to raise_error(StandardError)
    end

    xit "allows only plain text to be rendered" do
    end

  end
end
