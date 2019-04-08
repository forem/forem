require "rails_helper"

RSpec.describe HexComparer do
  it "returns biggest hex" do
    expect(described_class.new(["#ffffff", "#000000"]).biggest).to eq("#ffffff")
  end

  it "returns smallest hex" do
    expect(described_class.new(["#ffffff", "#000000"]).smallest).to eq("#000000")
  end

  it "orders hexes" do
    result = described_class.new(["#ffffff", "#111111", "#333333", "#000000"]).order
    expect(result).to eq(["#000000", "#111111", "#333333", "#ffffff"])
  end

  it "changes brightness to the smallest color" do
    hc = described_class.new(["#ccddee", "#ffffff"])
    expect(hc.brightness(0.5)).to eq("#666f77")
  end

  it "adds an accent to the smallest color" do
    hc = described_class.new(["#ccddee", "#ffffff"])
    expect(hc.accent).to eq("#d8eafc")
  end
end
