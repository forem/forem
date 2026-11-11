require "rails_helper"

RSpec.describe Admin::UsersQuery, type: :query do
  def create(name, *traits, **options)
    return super(:user, :without_profile, *traits, profile_image: nil, **options) if name == :user

    super
  end

  describe ".find" do
    let!(:user1) { create(:user, username: "user1") }
    let!(:user2) { create(:user, username: "user12") }

    it "returns nil for a blank identifier and finds a user by int id, string id, username, or email",
       :aggregate_failures do
      expect(described_class.find("")).to be_nil
      expect(described_class.find(user1.id.to_i)).to eq(user1)
      expect(described_class.find(user2.id.to_s)).to eq(user2)
      expect(described_class.find(user1.username)).to eq(user1)
      expect(described_class.find(user2.email)).to eq(user2)
    end
  end

  describe ".call" do
    let(:org1) { create(:organization, name: "Org1") }
    let(:org2) { create(:organization, name: "Org2") }

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
    let!(:all_users) { [user10, user9, user8, user7, user6, user5, user4, user3, user2, user] }

    it "returns all users by default and filters by search, role, roles, statuses, joining dates, ids, and limit",
       :aggregate_failures do
      expect(described_class.call).to eq(all_users)
      expect(described_class.call(search: "greg")).to eq([user2, user])

      expect(described_class.call(role: "tag_moderator")).to eq([user3])
      expect(described_class.call(role: "super_admin")).to eq([user6])
      expect(described_class.call(role: "trusted")).to eq([user5, user2, user])
      expect(described_class.call(role: "admin")).to eq([user5, user4])

      expect(
        described_class.call(roles: ["Admin", "Tech Admin", "Resource Admin: DataUpdateScript"]),
      ).to eq([user7, user5, user4])
      expect(described_class.call(statuses: ["Warned", "Comment Suspended"])).to eq([user10, user8])
      expect(described_class.call(statuses: ["Warned"], roles: ["Admin"])).to eq([user10, user5, user4])

      expect(described_class.call(joining_start: "01/12/2020", date_format: "DD/MM/YYYY")).to eq([user7])
      expect(described_class.call(joining_start: "12/01/2020", date_format: "MM/DD/YYYY")).to eq([user7])
      expect(described_class.call(joining_end: "07/05/2020", date_format: "DD/MM/YYYY")).to eq([user])
      expect(described_class.call(joining_end: "05/07/2020", date_format: "MM/DD/YYYY")).to eq([user])
      expect(
        described_class.call(joining_start: "01/05/2020", joining_end: "31/05/2020", date_format: "DD/MM/YYYY"),
      ).to eq([user3, user2, user])

      expect(described_class.call(ids: [user2.id, user3.id, user4.id])).to eq([user4, user3, user2])
      expect(described_class.call(ids: [0, "foo"])).to eq([])

      expect(described_class.call(limit: 2)).to eq([user10, user9])
      expect(described_class.call(limit: 0)).to eq(all_users)
      expect(described_class.call(limit: "foo")).to eq(all_users)
      expect(described_class.call(limit: nil)).to eq(all_users)
    end

    context "when given multiple single_resource_admin roles" do
      let(:roles) { ["Admin", "Super Admin", "Resource Admin: DataUpdateScript", "Resource Admin: Billboard"] }
      let!(:user8) { create(:user).tap { |u| u.add_role(:single_resource_admin, Billboard) } }
      # This user is provided to ensure our test looks for unique users even if they have duplicate roles
      let!(:user9) { create(:user, :super_admin).tap { |u| u.add_role(:single_resource_admin, Billboard) } }

      it "returns unique matching users across multiple single_resource_admin roles" do
        expect(described_class.call(roles: roles)).to eq([user9, user8, user7, user6, user5, user4])
      end
    end

    context "when given organizations" do
      it "filters by organizations alone and in combination with roles", :aggregate_failures do
        create(:organization_membership, user: user, organization: org1, type_of_user: "member")
        create(:organization_membership, user: user2, organization: org2, type_of_user: "member")

        expect(described_class.call(organizations: [org1.id, org2.id])).to eq([user2, user])

        create(:organization_membership, user: user4, organization: org2, type_of_user: "member")

        expect(described_class.call(organizations: [org1.id, org2.id], roles: ["Admin"])).to eq([user4])
      end
    end
  end
end
