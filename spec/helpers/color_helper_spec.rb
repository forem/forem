require "rails_helper"

describe ColorHelper do
  describe "gradient_from_hex" do
    it "accepts a hex string and returns an object with two colors for a gradient" do
      yellow = "#fff000"
      darker_yellow = "#9f9600"

      expect(helper.gradient_from_hex(yellow)).to eq({ light: yellow, dark: darker_yellow })
    end

    it "fails gracefully when given a bad hex string" do
      # default gradient is based on Dev.to brand defaults
      expect(helper.gradient_from_hex("#oops")).to eq({ light: "#oops", dark: "#oops" })
    end

    it "defaults to dev.to brand colors when given a non-string value" do
      # default gradient is based on Dev.to brand defaults
      expect(helper.gradient_from_hex(0o00000)).to eq({ light: "#4f46e5", dark: "#312c8f" })
    end
  end
end
