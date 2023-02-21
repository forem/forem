require "rails_helper"

RSpec.describe Color::Accessibility, type: :service do
  it "determines low contrast with default compared color" do
    expect(described_class.new("#8a9bb8").low_contrast?).to be true
  end

  it "determines low contrast with compared color input" do
    expect(described_class.new("#041d4a").low_contrast?("#1a3669")).to be true
  end

  it "determines low contrast with compared color and rate" do
    expect(described_class.new("#225CC9").low_contrast?("#ffffff", 10.0)).to be true
  end

  it "determines sufficient contrast with default compared color" do
    expect(described_class.new("#041d4a").low_contrast?).to be false
  end

  it "determines sufficient contrast with compared color input" do
    expect(described_class.new("#041d4a").low_contrast?("#e6eaf0")).to be false
  end

  it "determines sufficient contrast with compared color and rate" do
    expect(described_class.new("#225CC9").low_contrast?("#ffffff", 1.0)).to be false
  end

  describe "#reduce_brightness" do
    let(:color) { described_class.new("#fcf5f5") }

    it "returns a hex color than meets the minimum contrast requirment" do
      modified_color = color.reduce_brightness("ffffff", 4.5)
      ratio = WCAGColorContrast.ratio(modified_color, "ffffff")
      expect(ratio).to be > 4.5
    end

    context "when the original color meets the minimum contrast requirement" do
      let(:dark_color) { described_class.new("#041d4a") }

      it "does not modify the original hex color" do
        color = dark_color.reduce_brightness("ffffff", 4.5)
        expect(color).to eq "041d4a"
      end
    end
  end
end
