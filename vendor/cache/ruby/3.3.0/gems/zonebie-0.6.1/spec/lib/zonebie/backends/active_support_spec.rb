require "spec_helper"

describe Zonebie::Backends::ActiveSupport do
  describe "#name" do
    it "is :activesupport" do
      expect(described_class.name).to eq :activesupport
    end
  end

  describe "#zones" do
    it "returns a list of zones provided by ActiveSupport" do
      ::ActiveSupport::TimeZone.stubs(:all).returns([
        stub(:name => "Eastern Time (US & Canada)"),
        stub(:name => "Central Time (US & Canada)")
      ])

      expect(described_class.zones).to eq ["Eastern Time (US & Canada)", "Central Time (US & Canada)"]
    end
  end

  describe "#zone=" do
    it "sets Time.zone provided by ActiveSupport" do
      ::Time.expects(:zone=).with("Eastern Time (US & Canada)")

      described_class.zone = "Eastern Time (US & Canada)"
    end
  end

  describe "usable?" do
    it "returns true if ActiveSupport is available" do
      expect(described_class).to be_usable
    end

    it "returns false if ActiveSupport is unavailable" do
      old_active_support = ActiveSupport
      Object.send(:remove_const, :ActiveSupport)
      begin
        expect(described_class).not_to be_usable
      ensure
        ActiveSupport = old_active_support
      end
    end
  end
end
