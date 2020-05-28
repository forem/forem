require "rails_helper"

describe FeatureFlag, type: :helper do
  describe ".enabled?" do
    it "calls Flipper's enabled? method" do
      allow(Flipper).to receive(:enabled?).with("foo")

      described_class.enabled?("foo")

      expect(Flipper).to have_received(:enabled?).with("foo")
    end
  end

  describe ".exist?" do
    it "calls Flipper's exist? method" do
      allow(Flipper).to receive(:exist?).with("foo")

      described_class.exist?("foo")

      expect(Flipper).to have_received(:exist?).with("foo")
    end
  end
end
