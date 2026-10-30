require "rails_helper"

RSpec.describe Color::BrandPalette, type: :service do
  def contrast(foreground, background)
    Color::Accessibility.new(foreground).contrast_ratio(background)
  end

  describe "#text_on_brand" do
    it "uses black on a light brand color" do
      expect(described_class.new("#f5ff80").text_on_brand).to eq("#000000")
    end

    it "keeps white on a dark brand color" do
      expect(described_class.new("#3b49df").text_on_brand).to eq("#ffffff")
    end

    it "keeps white on black" do
      expect(described_class.new("#000000").text_on_brand).to eq("#ffffff")
    end

    it "checks the background it's given" do
      expect(described_class.new("#f5ff80").text_on_brand("#000000")).to eq("#ffffff")
    end

    it "accepts a three digit color" do
      expect(described_class.new("#ff8").text_on_brand).to eq("#000000")
    end
  end

  describe "accent text" do
    %w[#f5ff80 #000000 #ffffff #3b49df #ff6600 #808080 #abc].each do |hex|
      it "reads on the card in both themes for #{hex}", :aggregate_failures do
        palette = described_class.new(hex)

        expect(contrast(palette.accent_text_light, described_class::LIGHT_THEME_CARD))
          .to be >= described_class::MIN_CONTRAST
        expect(contrast(palette.accent_text_dark, described_class::DARK_THEME_CARD))
          .to be >= described_class::MIN_CONTRAST
      end
    end

    it "keeps a brand color that already reads" do
      expect(described_class.new("#3b49df").accent_text_light).to eq("#3b49df")
    end
  end

  describe "#lighter" do
    it "caps channels at 255", :aggregate_failures do
      palette = described_class.new("#f5ff80")

      expect(palette.lighter(1.35)).to eq("#ffffad")
      expect(palette.lighter(1.35, only_values: true)).to eq("255, 255, 173")
    end
  end
end
