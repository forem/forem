require "rails_helper"

RSpec.describe HexComparer do
  it "Returns biggest hex" do
    expect(described_class.new(["#ffffff", "#000000"]).biggest).to eq("#ffffff")
  end

  it "Returns smallest hex" do
    expect(described_class.new(["#ffffff", "#000000"]).smallest).to eq("#000000")
  end

  it "Orders hexes" do
    result = described_class.new(["#ffffff", "#111111", "#333333", "#000000"]).order
    expect(result).to eq(["#000000", "#111111", "#333333", "#ffffff"])
  end
end
