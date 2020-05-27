require "rails_helper"

RSpec.describe HexComparer, type: :labor do
  xit "returns biggest hex" do
    expect(described_class.new(["#ffffff", "#000000"]).biggest).to eq("#ffffff")
  end

  xit "returns smallest hex" do
    expect(described_class.new(["#ffffff", "#000000"]).smallest).to eq("#000000")
  end

  xit "orders hexes" do
    result = described_class.new(["#ffffff", "#111111", "#333333", "#000000"]).order
    expect(result).to eq(["#000000", "#111111", "#333333", "#ffffff"])
  end

  xit "changes brightness to the smallest color" do
    hc = described_class.new(["#ccddee", "#ffffff"])
    expect(hc.brightness(0.5)).to eq("#666f77")
  end

  xit "adds an accent to the smallest color" do
    hc = described_class.new(["#ccddee", "#ffffff"])
    expect(hc.accent).to eq("#d8eafc")
  end
end
