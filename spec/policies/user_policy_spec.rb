require "rails_helper"

RSpec.describe UserPolicy do
  subject { described_class.new(user, other_user) }

  let(:other_user) { build(:user) }

  context "when user is not signed-in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is signed-in" do
    let(:user) { other_user }

    it { is_expected.to permit_actions(%i[edit update onboarding_update join_org leave_org]) }

    context "with banned status" do
      before { user.add_role(:banned) }

      it { is_expected.to forbid_actions(%i[join_org]) }
    end
  end

  context "when user is org_admin" do
    let(:org) { build(:organization) }
    let(:other_org) { build(:organization) }
    let(:user) { build(:user, org_admin: true, organization: org) }


    context "with other_user as org_member of same org" do
      let(:other_user) { build(:user, organization: org) }

      it { is_expected.to permit_actions(%i[add_org_admin remove_from_org]) }
    end

    context "with other_user as org_member of a different org" do
      let(:other_user) { build(:user, organization: other_org) }

      it { is_expected.to forbid_actions(%i[add_org_admin remove_from_org]) }
    end

    context "with other_user as org admin" do
      let(:other_user) { build(:user, org_admin: true, organization: org) }

      it { is_expected.to permit_actions(%i[remove_org_admin]) }
    end

    context "with other_user as org adming of a different org" do
      let(:other_user) { build(:user, org_admin: true, organization: other_org) }

      it { is_expected.to forbid_actions(%i[remove_org_admin]) }
    end
  end
end
