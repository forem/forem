require "rails_helper"

RSpec.describe Admin::UsersQuery, type: :query do
  subject { described_class.call(search: search, role: role, roles: roles, organizations: organizations) }

  let(:role) { nil }
  let(:roles) { [] }
  let(:organizations) { [] }
  let(:search) { [] }

  let!(:org1) { create(:organization, name: "Org1") }
  let!(:org2) { create(:organization, name: "Org2") }

  let!(:user)  { create(:user, :trusted, name: "Greg") }
  let!(:user2) { create(:user, :trusted, name: "Gregory") }
  let!(:user3) { create(:user, :tag_moderator, name: "Paul") }
  let!(:user4) { create(:user, :admin, name: "Susi") }
  let!(:user5) { create(:user, :trusted, :admin, name: "Beth") }
  let!(:user6) { create(:user, :super_admin, name: "Jean") }
  let!(:user7) { create(:user).tap { |u| u.add_role(:single_resource_admin, DataUpdateScript) } }

  describe ".call" do
    context "when no arguments are given" do
      it "returns all users" do
        expect(described_class.call).to eq([user7, user6, user5, user4, user3, user2, user])
      end
    end

    context "when search is set" do
      let(:search) { "greg" }

      it { is_expected.to eq([user2, user]) }
    end

    context "when role is tag_moderator" do
      let(:role) { "tag_moderator" }

      it { is_expected.to eq([user3]) }
    end

    context "when role is super_admin" do
      let(:role) { "super_admin" }

      it { is_expected.to eq([user6]) }
    end

    context "when role is trusted" do
      let(:role) { "trusted" }

      it { is_expected.to eq([user5, user2, user]) }
    end

    context "when role is admin" do
      let(:role) { "admin" }

      it { is_expected.to eq([user5, user4]) }
    end

    context "when roles is multiple" do
      let(:roles) { ["Admin", "Tech Admin", "Resource Admin: DataUpdateScript"] }

      it { is_expected.to eq([user7, user5, user4]) }
    end

    context "when given multiple single_resource_admin roles" do
      let(:roles) { ["Admin", "Super Admin", "Resource Admin: DataUpdateScript", "Resource Admin: DisplayAd"] }
      let!(:user8) { create(:user).tap { |u| u.add_role(:single_resource_admin, DisplayAd) } }

      it { is_expected.to eq([user8, user7, user6, user5, user4]) }
    end

    context "when given organizations" do
      before do
        create(:organization_membership, user: user, organization: org1, type_of_user: "member")
        create(:organization_membership, user: user2, organization: org2, type_of_user: "member")
      end

      let(:organizations) { [org1.id, org2.id] }

      it { is_expected.to eq([user2, user]) }
    end

    context "when given organizations and roles" do
      before do
        create(:organization_membership, user: user, organization: org1, type_of_user: "member")
        create(:organization_membership, user: user4, organization: org2, type_of_user: "member")
      end

      let(:organizations) { [org1.id, org2.id] }
      let(:roles) { ["Admin"] }

      it { is_expected.to eq([user4]) }
    end
  end
end
