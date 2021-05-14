require "rails_helper"

RSpec.describe Settings::UserExperience do
  describe "validating hex string format" do
    it "allows 3 chacter hex strings" do
      expect do
        described_class.primary_brand_color_hex = "#000"
      end.not_to raise_error
    end

    it "allows 6 character hex strings" do
      expect do
        described_class.primary_brand_color_hex = "#000000"
      end.not_to raise_error
    end

    it "rejects strings without leading #" do
      expect do
        described_class.primary_brand_color_hex = "000000"
      end.to raise_error(/must be be a 3 or 6 character hex \(starting with #\)/)
    end

    it "rejects invalid character" do
      expect do
        described_class.primary_brand_color_hex = "#00000g"
      end.to raise_error(/must be be a 3 or 6 character hex \(starting with #\)/)
    end
  end

  describe "validating color contrast" do
    it "allows high enough color contrast" do
      expect do
        described_class.primary_brand_color_hex = "#000"
      end.not_to raise_error
    end

    it "rejects too low color contrast" do
      expect do
        described_class.primary_brand_color_hex = "#fff"
      end.to raise_error(/must be darker for accessibility/)
    end
  end
end
