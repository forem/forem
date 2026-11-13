require "rails_helper"

RSpec.describe OrganizationMembershipPolicy, type: :policy do
  let(:membership) { create(:organization_membership, type_of_user: "pending") }

  context "when user is not signed in" do
    subject { described_class.new(nil, membership) }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when user is the invitee" do
    subject { described_class.new(membership.user, membership) }

    it { is_expected.to permit_actions(%i[accept decline]) }
  end

  context "when user is someone else" do
    subject { described_class.new(create(:user), membership) }

    it { is_expected.to forbid_actions(%i[accept decline]) }
  end
end
