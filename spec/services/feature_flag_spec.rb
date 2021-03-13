require "rails_helper"

UserStruct = Struct.new(:flipper_id)

describe FeatureFlag, type: :service do
  describe ".enable" do
    it "calls Flipper's enable method" do
      allow(Flipper).to receive(:enable).with("foo")

      described_class.enable("foo")

      expect(Flipper).to have_received(:enable).with("foo")
    end

    it "enables the feature" do
      described_class.enable("foo")

      expect(described_class.enabled?("foo")).to be(true)
    end
  end

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

  describe ".accessible?" do
    let(:user) { UserStruct.new(flipper_id: 1) }

    it "returns false when flag doesn't exist" do
      expect(described_class.accessible?("missing_flag")).to be(true)
    end

    it "returns true when flag is empty" do
      expect(described_class.accessible?("")).to be(true)
    end

    it "returns true when flag is nil" do
      expect(described_class.accessible?(nil)).to be(true)
    end

    context "when flag exists and is set to off" do
      before { Flipper.disable("flag") }

      it "returns false" do
        expect(described_class.accessible?("flag")).to be(false)
      end

      it "returns true when flag is on for user" do
        Flipper.enable_actor("flag", user)
        expect(described_class.accessible?("flag", user)).to be(true)
      end
    end

    context "when flag exists and is set to on" do
      before { Flipper.enable("flag") }

      it "returns true" do
        expect(described_class.accessible?("flag")).to be(true)
      end

      it "returns true for a user" do
        expect(described_class.accessible?("flag", user)).to be(true)
      end
    end
  end
end
