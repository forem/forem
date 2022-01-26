require "rails_helper"
RSpec.describe Notifications::NewFollower::FollowData do
  let(:valid_attributes) { { "followable_id" => 1, "followable_type" => "User", "follower_id" => 2 } }

  describe ".coerce" do
    subject(:coercion) { described_class.coerce(coercible) }

    context "when given a Follow" do
      let(:coercible) { create(:follow) }

      it { is_expected.to be_a(described_class) }
    end

    context "when given a Notifications::Reactions::ReactionData" do
      let(:coercible) { described_class.new(valid_attributes) }

      it "returns the given object" do
        expect(coercion.object_id).to eq(coercible.object_id)
      end
    end

    context "when given valid attributes" do
      let(:coercible) { valid_attributes }

      it { is_expected.to be_a(described_class) }
    end

    context "when given invalid attributes" do
      let(:coercible) { valid_attributes.merge(followable_type: "Ruby Slipper") }

      it "raises an DataError exception" do
        expect { coercion }.to raise_error(described_class::DataError)
      end
    end
  end

  describe "#to_h" do
    it "returns a hash" do
      obj = described_class.new(valid_attributes)
      expect(obj.to_h).to eq(valid_attributes)
    end
  end
end
