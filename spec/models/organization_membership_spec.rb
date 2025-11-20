require "rails_helper"

RSpec.describe OrganizationMembership do
  describe "validations" do
    subject { build(:organization_membership) }

    let(:organization) { create(:organization) }

    it { is_expected.to validate_presence_of(:type_of_user) }
    it { is_expected.to validate_uniqueness_of(:user_id).scoped_to(:organization_id) }
    it { is_expected.to validate_inclusion_of(:type_of_user).in_array(OrganizationMembership::USER_TYPES) }
  end

  describe "scopes" do
    let(:organization) { create(:organization) }
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:user3) { create(:user) }

    before do
      create(:organization_membership, organization: organization, user: user1, type_of_user: "admin")
      create(:organization_membership, organization: organization, user: user2, type_of_user: "member")
      create(:organization_membership, organization: organization, user: user3, type_of_user: "pending")
    end

    describe ".pending" do
      it "returns only pending memberships" do
        expect(organization.organization_memberships.pending.count).to eq(1)
        expect(organization.organization_memberships.pending.first.user).to eq(user3)
      end
    end

    describe ".active" do
      it "returns only non-pending memberships" do
        expect(organization.organization_memberships.active.count).to eq(2)
        expect(organization.organization_memberships.active.pluck(:user_id)).to contain_exactly(user1.id, user2.id)
      end
    end
  end

  describe "#pending?" do
    it "returns true for pending memberships" do
      membership = create(:organization_membership, type_of_user: "pending")
      expect(membership.pending?).to be true
    end

    it "returns false for non-pending memberships" do
      membership = create(:organization_membership, type_of_user: "member")
      expect(membership.pending?).to be false
    end
  end

  describe "#confirm!" do
    let(:membership) { create(:organization_membership, type_of_user: "pending") }

    it "changes type_of_user from pending to member" do
      expect(membership.type_of_user).to eq("pending")
      membership.confirm!
      expect(membership.reload.type_of_user).to eq("member")
    end

    it "updates the membership" do
      expect { membership.confirm! }.to change { membership.reload.type_of_user }.from("pending").to("member")
    end
  end

  describe "invitation_token generation" do
    it "generates an invitation token for pending memberships" do
      membership = build(:organization_membership, type_of_user: "pending", invitation_token: nil)
      membership.save!
      expect(membership.invitation_token).to be_present
    end

    it "does not generate an invitation token for non-pending memberships" do
      membership = build(:organization_membership, type_of_user: "member", invitation_token: nil)
      membership.save!
      expect(membership.invitation_token).to be_nil
    end

    it "preserves existing invitation token if present" do
      existing_token = "existing-token-123"
      membership = build(:organization_membership, type_of_user: "pending", invitation_token: existing_token)
      membership.save!
      expect(membership.invitation_token).to eq(existing_token)
    end
  end
end
