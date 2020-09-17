require "rails_helper"

RSpec.describe HexComparer, type: :labor do
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
