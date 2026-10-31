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

    it "loads SVGs from the boot-time CachedAssetFile without reading from disk per render" do
      expect(InlineSvg.configuration.asset_file).to be_a(InlineSvg::CachedAssetFile)
      allow(File).to receive(:read).and_call_original

      helper.crayons_icon_tag("twitter")

      expect(File).not_to have_received(:read)
    end

    %w[favorite-checked small-favorite-checked].each do |icon|
      it "draws the #{icon} checkmark in a dark stroke so it contrasts with the yellow gem" do
        icon_tag = helper.crayons_icon_tag(icon, native: true)
        expect(icon_tag).to include('stroke="#171717"')
        expect(icon_tag).not_to include('stroke="#fff"')
      end
    end

    it "keeps the hand-inlined small-favorite-checked copy in buildArticleHTML.js in sync" do
      svg = Rails.root.join("app/assets/images/small-favorite-checked.svg").read
      checkmark = svg[%r{<path d="M10 11[^>]*/>}]
      builder = Rails.root.join("app/assets/javascripts/utilities/buildArticleHTML.js").read

      expect(checkmark).to include('stroke="#171717"')
      expect(builder).to include(checkmark)
    end
  end
end
