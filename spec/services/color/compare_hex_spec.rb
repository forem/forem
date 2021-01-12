require "rails_helper"

RSpec.describe Color::CompareHex, type: :service do
  describe "constant definitions" do
    it "defines ACCENT_MODIFIERS" do
      accent_modifiers = [1.14, 1.08, 1.06, 0.96, 0.9, 0.8, 0.7, 0.6]
      expect(described_class::ACCENT_MODIFIERS).to eq accent_modifiers
    end

    it "defines BRIGHTNESS_FORMAT" do
      expect(described_class::BRIGHTNESS_FORMAT).to eq "#%<r>02x%<g>02x%<b>02x"
    end

    it "defines OPACITY_FORMAT" do
      expect(described_class::OPACITY_FORMAT).to eq "rgba(%<r>d, %<g>d, %<b>d, %<a>.2f)"
    end

    it "defines RGB_REGEX" do
      expect(described_class::RGB_REGEX).to eq(/^#?(?<r>..)(?<g>..)(?<b>..)$/)
    end
  end

  it "returns biggest hex" do
    expect(described_class.new(["#ffffff", "#000000"]).biggest).to eq("#ffffff")
  end

  it "returns smallest hex" do
    expect(described_class.new(["#ffffff", "#000000"]).smallest).to eq("#000000")
  end

  it "changes brightness to the smallest color" do
    hc = described_class.new(["#ccddee", "#ffffff"])
    expect(hc.brightness(0.5)).to eq("#666f77")
  end

  it "adds an accent to the smallest color" do
    hc = described_class.new(["#ccddee", "#ffffff"])
    expect(hc.accent).to eq("#d8eafc")
  end

  it "generates an rgba value with opactity" do
    rgba = described_class.new(["#123456"]).opacity(0.5)
    expect(rgba).to eq("rgba(18, 52, 86, 0.50)")
  end
end
