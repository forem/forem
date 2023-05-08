require "rails_helper"

RSpec.describe CtaTag, type: :liquid_tag do
  describe "#render" do
    let(:link) { "https://dev.to/" }
    let(:only_link_option) { link }

    let(:style) { "branded" }
    let(:link_style_options) { "#{link} #{style}" }

    let(:width) { "block" }
    let(:link_style_width_options) { "#{link} #{style} #{width}" }

    let(:link_width_options) { "#{link} #{width}" }
    let(:unordered_options) { "#{link} #{width} #{style}" }

    let(:description) { "DEV Community" }

    # test case where no link provided
    # do we want to account for alignment

    def generate_details_liquid(options, description)
      Liquid::Template.register_tag("cta", described_class)
      Liquid::Template.parse("{% cta #{options} %} #{description} {% endcta %}")
    end

    it "contains the correct static attribuutes" do
      rendered = generate_details_liquid(link_style_options, description).render
      expect(rendered).to include("class=\"ltag_cta")
      expect(rendered).to include("role=\"button")
    end

    it "generates the correct href attribute" do
      rendered = generate_details_liquid(link_style_options, description).render
      expect(rendered).to include("href=\"#{link}")
    end

    it "contains the correct description" do
      rendered = generate_details_liquid(link_style_options, description).render
      expect(rendered).to include(description)
    end

    xit "limits the description to 128 characters" do
      expect do
        generate_details_liquid(link_style_options, "We do not allow for more than hundred and twenty eight characters
          in the description of the CTA. This is the same as what we allow for article titles.").render
      end.to raise_error(StandardError)
    end

    xit "allows only plain text to be rendered" do
    end

    context "when given a style attribute" do
      it "contains the style attribute provided" do
        rendered = generate_details_liquid(link_style_options, description).render
        expect(rendered).to include("class=\"ltag_cta ltag_cta--branded")
      end
    end

    context "when not given a style attribute" do
      it "sets the default style attribute when one is not provided" do
        rendered = generate_details_liquid(only_link_option, description).render
        expect(rendered).to include("class=\"ltag_cta ltag_cta--branded")
      end
    end

    context "when given a width attribute" do
      it "contains the width attribute provided" do
        rendered = generate_details_liquid(link_style_width_options, description).render
        expect(rendered).to include("block")
      end
    end

    context "when not given a width attribute" do
      it "sets the default width attribute when one is not provided" do
        rendered = generate_details_liquid(only_link_option, description).render
        expect(rendered).to include("inline")
      end
    end

    it "does not matter what order the CTA receives its options" do
      rendered = generate_details_liquid(unordered_options, description).render
      expect(rendered).to include("class=\"ltag_cta ltag_cta--branded")
      expect(rendered).to include("block")
    end
  end
end
