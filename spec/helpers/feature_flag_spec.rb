require "rails_helper"

UserStruct = Struct.new(:flipper_id)

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

  describe ".accessible?" do
    let(:user) { UserStruct.new(flipper_id: 1) }

    it "returns false when flag doesn't exist" do
      expect(described_class.accessible?("missing_flag")).to be_truthy # rubocop:disable Rspec/PredicateMatcher
    end

    it "returns true when flag is empty" do
      expect(described_class.accessible?("")).to be_truthy # rubocop:disable Rspec/PredicateMatcher
    end

    it "returns true when flag is nil" do
      expect(described_class.accessible?(nil)).to be_truthy # rubocop:disable Rspec/PredicateMatcher
    end

    context "when flag exists and is set to off" do
      before { Flipper.disable("flag") }

      it "returns false" do
        expect(described_class.accessible?("flag")).to be_falsy # rubocop:disable Rspec/PredicateMatcher
      end

      it "returns true when flag is on for user" do
        Flipper.enable_actor("flag", user)
        expect(described_class.accessible?("flag", user)).to be_truthy # rubocop:disable Rspec/PredicateMatcher
      end
    end

    context "when flag exists and is set to on" do
      before { Flipper.enable("flag") }

      it "returns true" do
        expect(described_class.accessible?("flag")).to be_truthy # rubocop:disable Rspec/PredicateMatcher
      end

      it "returns true for a user" do
        expect(described_class.accessible?("flag", user)).to be_truthy # rubocop:disable Rspec/PredicateMatcher
      end
    end
  end
end
