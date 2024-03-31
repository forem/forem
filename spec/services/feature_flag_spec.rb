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
    subject(:method_call) { described_class.enabled?(flag) }

    let(:flag) { "foo" }

    it "calls Flipper's enabled? method" do
      allow(Flipper).to receive(:enabled?).with(flag)

      described_class.enabled?(flag)

      expect(Flipper).to have_received(:enabled?).with(flag)
    end

    context "when flag explicitly enabled" do
      before { described_class.enable(flag) }

      it { is_expected.to be_truthy }
    end

    context "when flag doesn't exist" do
      it { is_expected.to be_falsey }
    end

    context "when flag explicitly disabled" do
      before { described_class.disable(flag) }

      it { is_expected.to be_falsey }
    end
  end

  describe ".enabled_for_user?" do
    subject(:method_call) { described_class.enabled?(flag) }

    let(:flag) { "foo" }
    let(:user) { build(:user) }

    it "calls Flipper's enabled? method" do
      allow(Flipper).to receive(:enabled?)

      described_class.enabled_for_user?(flag, user)

      expect(Flipper).to have_received(:enabled?).with(flag, instance_of(FeatureFlag::Actor))
    end
  end

  describe ".enabled_for_user_id?" do
    subject(:method_call) { described_class.enabled?(flag) }

    let(:flag) { "foo" }
    let(:user) { build(:user) }

    it "calls Flipper's enabled? method" do
      allow(Flipper).to receive(:enabled?)

      described_class.enabled_for_user_id?(flag, user.id)

      expect(Flipper).to have_received(:enabled?).with(flag, instance_of(FeatureFlag::Actor))
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
    let(:user) { UserStruct.new({ flipper_id: 1 }) }

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

  describe ".all", :aggregate_failures do
    it "returns a hash with all feature flags and their status" do
      described_class.enable(:flag1)
      expect(described_class.all).to eq({ flag1: :on })

      described_class.disable(:flag2)
      expect(described_class.all).to eq({ flag1: :on, flag2: :off })
    end
  end

  describe FeatureFlag::Actor, type: :service do
    context "when user object" do
      subject(:actor) { described_class[user] }

      let(:user_id) { 123 }
      let(:user) { User.new id: user_id }

      it "represents flipper_id as user.id" do
        expect(actor.flipper_id).to eq(user_id)
      end
    end

    context "when user_id" do
      subject(:actor) { described_class[user_id] }

      let(:user_id) { 123 }

      it "represents flipper_id as user.id" do
        expect(actor.flipper_id).to eq(user_id)
      end
    end
  end
end
