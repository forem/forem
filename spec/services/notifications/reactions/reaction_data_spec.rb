require "rails_helper"

RSpec.describe Notifications::Reactions::ReactionData do
  let(:valid_attributes) { { "reactable_id" => 1, "reactable_type" => "Comment", "reactable_user_id" => 2, "reactable_subforem_id" => nil } }

  describe ".coerce" do
    subject(:coercion) { described_class.coerce(coercible) }

    context "when given a Reaction" do
      let(:coercible) { create(:reaction) }

      it { is_expected.to be_a(described_class) }
    end

    context "when given a Notifications::Reactions::ReactionData" do
      let(:coercible) { described_class.new(valid_attributes) }

      it "returns the given object" do
        expect(coercion.object_id).to eq(coercible.object_id)
      end
    end

    context "when given valid attributes" do
      let(:coercible) { valid_attributes  }

      it { is_expected.to be_a(described_class) }
    end

    context "when given invalid attributes" do
      let(:coercible) { valid_attributes.merge(reactable_type: "RubySlipper") }

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
