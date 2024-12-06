require "unit_spec_helper"

describe Rpush::DeliveryError do
  let(:error) { Rpush::DeliveryError.new(4, 12, "Missing payload") }

  it "returns an informative message" do
    expect(error.to_s).to eq "Unable to deliver notification 12, received error 4 (Missing payload)"
  end

  it "returns the error code" do
    expect(error.code).to eq 4
  end
end
