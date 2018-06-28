require "rails_helper"

RSpec.describe OrganizationPolicy do
  subject { described_class.new(user, organization) }

  let(:organization) { build(:organization) }

  context "when user is not signed-in" do
    let(:user) { nil }

    it { within_block_is_expected.to raise_error(Pundit::NotAuthorizedError) }
  end

  context "when a non-org user" do
    let(:user) { build(:user) }

    it { is_expected.to forbid_action(:update) }
    it { is_expected.to permit_action(:create) }
  end

  context "when user is banned" do
    let(:user) { build(:user, :banned) }

    it { is_expected.to forbid_actions(%i[create update]) }
  end

  context "when user is an org admin of an org" do
    let(:user) { build(:user) }

    before { user.update(organization: organization, org_admin: true) }

    it "allows the user to update their own org" do
      is_expected.to permit_action(:update)
    end
  end

  context "when user is an org admin of another org" do
    let(:user) { build(:user) }
    let(:new_org) { build(:organization) }

    before { user.update(organization: new_org, org_admin: true) }

    it "does not allow the user to update another org" do
      is_expected.to forbid_action(:update)
    end
  end
end
