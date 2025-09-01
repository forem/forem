require "rails_helper"

RSpec.describe SubforemPolicy do
  let(:user) { create(:user) }
  let(:subforem) { create(:subforem, domain: "test-policy.com") }
  let(:policy) { described_class.new(user, subforem) }

  describe "#index?" do
    context "when user is a super admin" do
      let(:user) { create(:user, :super_admin) }

      it "returns true" do
        expect(policy.index?).to be true
      end
    end

    context "when user is a subforem moderator" do
      before do
        user.add_role(:subforem_moderator, create(:subforem, domain: "test-moderator.com"))
      end

      it "returns true" do
        expect(policy.index?).to be true
      end
    end

    context "when user is not a super admin or subforem moderator" do
      it "returns false" do
        expect(policy.index?).to be false
      end
    end
  end

  describe "#edit?" do
    context "when user is a super admin" do
      let(:user) { create(:user, :super_admin) }

      it "returns true" do
        expect(policy.edit?).to be true
      end
    end

    context "when user is a subforem moderator for the subforem" do
      before do
        user.add_role(:subforem_moderator, subforem)
      end

      it "returns true" do
        expect(policy.edit?).to be true
      end
    end

    context "when user is not a super admin or subforem moderator" do
      it "returns false" do
        expect(policy.edit?).to be false
      end
    end
  end

  describe "#update?" do
    context "when user is a super admin" do
      let(:user) { create(:user, :super_admin) }

      it "returns true" do
        expect(policy.update?).to be true
      end
    end

    context "when user is a subforem moderator for the subforem" do
      before do
        user.add_role(:subforem_moderator, subforem)
      end

      it "returns true" do
        expect(policy.update?).to be true
      end
    end

    context "when user is not a super admin or subforem moderator" do
      it "returns false" do
        expect(policy.update?).to be false
      end
    end
  end

  describe "#admin?" do
    context "when user is a super admin" do
      let(:user) { create(:user, :super_admin) }

      it "returns true" do
        expect(policy.admin?).to be true
      end
    end

    context "when user is not a super admin" do
      it "returns false" do
        expect(policy.admin?).to be false
      end
    end
  end
end
