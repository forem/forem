require "rails_helper"

RSpec.describe StringToBool, type: :refinement do
  describe "#to_bool" do
    using described_class
    it "converts a string to a boolean" do
      expect("true".to_bool).to eq true
    end
  end
end
