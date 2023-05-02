require "rails_helper"

RSpec.describe CtaTag, type: :liquid_tag do
  describe "#render" do
    let(:link) { "https://dev.to/" }
    let(:description) { "DEV Community" }

    def generate_details_liquid(link, description)
      Liquid::Template.register_tag("cta", described_class)
      Liquid::Template.parse("{% cta #{link} %} #{description} {% endcta %}")
    end

    it "generates proper details div with link" do
      rendered = generate_details_liquid(link, description).render

      expect(rendered).to include("href=\"#{link}")
      expect(rendered).to include("class=\"crayons-btn ml-auto")
      expect(rendered).to include("role=\"button")
      expect(rendered).to include(description)
    end
  end
end
