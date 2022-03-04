require "rails_helper"

RSpec.describe StringToBoolean, type: :refinement do
  describe "#to_boolean" do
    using described_class
    it "converts a string to a boolean" do
      expect("true".to_boolean).to be true
    end
  end
end
