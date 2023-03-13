require "rails_helper"

RSpec.describe CrayonsHelper do
  describe "#crayons_icon_tag" do
    let(:icon_tag) { helper.crayons_icon_tag("twitter.svg") }

    it "generates an SVG tag" do
      expect(icon_tag).to match(%r{\A<svg.*</svg>\n\z}m)
    end

    it "includes the correct class" do
      expect(icon_tag).to match(/class="crayons-icon"/)
    end

    it "allows disabling color inheritance via the native attribute" do
      icon_tag = helper.crayons_icon_tag(:twitter, native: true)
      expect(icon_tag).to match(/class="crayons-icon crayons-icon--default"/)
    end

    it "adds the correct ARIA role" do
      expect(icon_tag).to match(/role="img"/)
    end

    it "works when the .svg suffix is omitted" do
      expect(helper.crayons_icon_tag("twitter")).to eq(icon_tag)
    end

    it "accepts a symbol for the name parameter" do
      expect(helper.crayons_icon_tag(:twitter)).to eq(icon_tag)
    end

    it "allows specifying additional CSS classes" do
      icon_tag = helper.crayons_icon_tag("twitter", class: "pointer-events-none")
      expect(icon_tag).to match(/class="crayons-icon pointer-events-none"/)
    end

    it "passes additional keyword arguments to the wrapped tag" do
      icon_tag = helper.crayons_icon_tag("twitter", title: "Test")
      expect(icon_tag).to match(%r{<title.*>Test</title>})
    end

    it "allows mixing extra classes and the native option" do
      icon_tag = helper.crayons_icon_tag(:twitter, class: "test", native: true)
      expect(icon_tag).to match(/class="crayons-icon crayons-icon--default test"/)
    end
  end
end
