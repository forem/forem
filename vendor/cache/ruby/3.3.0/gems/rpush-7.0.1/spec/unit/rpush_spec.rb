require 'unit_spec_helper'

describe Rpush do
  it "lazy initializes the logger" do
    expect(Rpush::Logger).to receive(:new)
    Rpush.logger
  end
end
