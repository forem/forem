require 'rails_helper'

RSpec.describe HexComparer do
  it "Returns biggest hex" do
    expect(HexComparer.new(["#ffffff","#000000"]).biggest).to eq("#ffffff")
  end

  it "Returns smallest hex" do
    expect(HexComparer.new(["#ffffff","#000000"]).smallest).to eq("#000000")
  end

  it "Orders hexes" do
    expect(HexComparer.new(["#ffffff","#111111","#333333","#000000"]).order).to eq(["#000000","#111111","#333333","#ffffff"])
  end
end
