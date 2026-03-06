require "rails_helper"

RSpec.describe "Offer liquid tag", type: :liquid_tag do
  before do
    Liquid::Template.register_tag("offer", OfferTag)
  end

  def parse(template)
    Liquid::Template.parse(template)
  end

  describe "basic rendering" do
    it "renders an offer banner with content" do
      result = parse('{% offer %}Join us today!{% endoffer %}').render
      expect(result).to include('class="ltag-offer"')
      expect(result).to include("ltag-offer__body")
      expect(result).to include("Join us today!")
    end

    it "renders without a button when no link is provided" do
      result = parse('{% offer %}Just info{% endoffer %}').render
      expect(result).not_to include("ltag-offer__button")
    end
  end

  describe "link and button" do
    it "renders a button when link is provided" do
      result = parse('{% offer link="https://example.com" %}Sign up now{% endoffer %}').render
      expect(result).to include("ltag-offer__button")
      expect(result).to include('href="https://example.com"')
      expect(result).to include("Learn More")
    end

    it "renders custom button text" do
      result = parse('{% offer link="https://example.com" button="Sign Up" %}Get started{% endoffer %}').render
      expect(result).to include("Sign Up")
      expect(result).not_to include("Learn More")
    end

    it "renders button with quoted text" do
      result = parse('{% offer link="https://example.com" button="Get Started Now" %}Promo text{% endoffer %}').render
      expect(result).to include("Get Started Now")
    end
  end

  describe "content" do
    it "preserves HTML content" do
      result = parse('{% offer %}<strong>Bold offer</strong>{% endoffer %}').render
      expect(result).to include("<strong>Bold offer</strong>")
    end
  end
end
