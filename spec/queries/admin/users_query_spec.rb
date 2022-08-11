require "rails_helper"

RSpec.describe Admin::UsersQuery, type: :query do
  let(:role) { nil }
  let(:roles) { [] }
  let(:statuses) { [] }
  let(:organizations) { [] }
  let(:search) { [] }
  let(:joining_start) { nil }
  let(:joining_end) { nil }

  describe ".find" do
    let!(:user1) { create :user, username: "user1" }
    let!(:user2) { create :user, username: "user12" }

    context "when identifier is blank" do
      it "returns nil" do
        expect(described_class.find("")).to be_nil
      end
    end

    context "when identifier is an int id" do
      let(:id) { user1.id.to_i }

      it "returns user by id" do
        expect(described_class.find(id)).to eq(user1)
      end
    end

    context "when identifier is a string 'id'" do
      let(:id) { user2.id.to_s }

      it "returns user by id" do
        expect(described_class.find(id)).to eq(user2)
      end
    end

    context "when identifier is a username" do
      let(:id) { user1.username }

      it "returns user by id" do
        expect(described_class.find(id)).to eq(user1)
      end
    end

    context "when identifier is an email" do
      let(:id) { user2.email }

      it "returns user by id" do
        expect(described_class.find(id)).to eq(user2)
      end
    end
  end

  describe ".call" do
    subject do
      described_class.call(search: search, role: role, roles: roles, organizations: organizations,
                           joining_start: joining_start, joining_end: joining_end, date_format: date_format,
                           statuses: statuses)
    end

    let(:date_format) { "DD/MM/YYYY" }

    let!(:org1) { create(:organization, name: "Org1") }
    let!(:org2) { create(:organization, name: "Org2") }

    let!(:user)  { create(:user, :trusted, name: "Greg", registered_at: "2020-05-06T13:09:47+0000") }
    let!(:user2) { create(:user, :trusted, name: "Gregory", registered_at: "2020-05-08T13:09:47+0000") }
    let!(:user3) { create(:user, :tag_moderator, name: "Paul", registered_at: "2020-05-10T13:09:47+0000") }
    let!(:user4) { create(:user, :admin, name: "Susi", registered_at: "2020-10-05T13:09:47+0000") }
    let!(:user5) { create(:user, :trusted, :admin, name: "Beth", registered_at: "2020-10-07T13:09:47+0000") }
    let!(:user6) { create(:user, :super_admin, name: "Jean", registered_at: "2020-10-08T13:09:47+0000") }
    let!(:user7) do
      create(:user, name: "Joanna", registered_at: "2020-12-05T13:09:47+0000").tap do |u|
        u.add_role(:single_resource_admin, DataUpdateScript)
      end
    end
    let!(:user8) { create(:user, :comment_suspended, name: "Bob", registered_at: "2020-10-08T13:09:47+0000") }
    let!(:user9) { create(:user, name: "Lucia",  registered_at: "2020-10-08T13:09:47+0000") }
    let!(:user10) { create(:user, :warned, name: "Billie", registered_at: "2020-10-08T13:09:47+0000") }

    context "when no arguments are given" do
      it "returns all users" do
        expect(described_class.call).to eq([user10, user9, user8, user7, user6, user5, user4, user3, user2, user])
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
      # This user is provided to ensure our test looks for unique users even if they have duplicate roles
      let!(:user9) { create(:user, :super_admin).tap { |u| u.add_role(:single_resource_admin, DisplayAd) } }

      it { is_expected.to eq([user9, user8, user7, user6, user5, user4]) }
    end

    context "when given statuses" do
      let(:statuses) { ["Warned", "Comment Suspended"] }

      it { is_expected.to eq([user10, user8]) }
    end

    context "when given both roles and statuses" do
      let(:statuses) { ["Warned"] }
      let(:roles) { ["Admin"] }

      it { is_expected.to eq([user10, user5, user4]) }
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

    context "when filtering by joining_start and default DD/MM/YYYY date format" do
      let(:joining_start) { "01/12/2020" }

      it { is_expected.to eq([user7]) }
    end

    context "when filtering by joining_start and alternative MM/DD/YYYY date format" do
      let(:joining_start) { "12/01/2020" }
      let(:date_format) { "MM/DD/YYYY" }

      it { is_expected.to eq([user7]) }
    end

    context "when filtering by joining_end and default DD/MM/YYYY date format" do
      let(:joining_end) { "07/05/2020" }

      it { is_expected.to eq([user]) }
    end

    context "when filtering by joining_end and alternative MM/DD/YYYY date format" do
      let(:joining_end) { "05/07/2020" }
      let(:date_format) { "MM/DD/YYYY" }

      it { is_expected.to eq([user]) }
    end

    context "when filtering by both joining_start and joining_end" do
      let(:joining_start) { "01/05/2020" }
      let(:joining_end) { "31/05/2020" }

      it { is_expected.to eq([user3, user2, user]) }
    end
  end
end
