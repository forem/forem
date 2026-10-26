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

    it "renders each icon and option set through inline_svg only once per process" do
      described_class::ICON_CACHE.clear
      allow(helper).to receive(:inline_svg_tag).and_call_original

      first = helper.crayons_icon_tag(:twitter, class: "memo-test")
      second = helper.crayons_icon_tag(:twitter, class: "memo-test")

      expect(second).to eq(first)
      expect(second).to be_html_safe
      expect(helper).to have_received(:inline_svg_tag).once
    end

    it "gives every render fresh, matching aria-labelledby ids for the title and description" do
      tags = Array.new(2) { helper.crayons_icon_tag(:twitter, title: "Same", desc: "Desc") }
      id_lists = tags.map { |tag| tag[/aria-labelledby="([^"]+)"/, 1].split }

      expect(id_lists.flatten.uniq.size).to eq(4)
      tags.zip(id_lists).each do |tag, ids|
        expect(tag).to include(%(<title id="#{ids.first}">Same</title>))
        expect(tag).to include(%(<desc id="#{ids.last}">Desc</desc>))
      end
    end
  end
end
