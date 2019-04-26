require "rails_helper"

RSpec.describe "UserOrganization", type: :request do
  let(:user)          { create(:user) }
  let(:organization)  { create(:organization, secret: "SECRET", approved: true) }

  context "when joining an org" do
    before { sign_in user }

    it "creates an organization_membership association" do
      post "/users/join_org", params: { org_secret: organization.secret }
      org_membership = OrganizationMembership.first
      expect(org_membership.persisted?).to eq true
      expect(org_membership.user).to eq user
      expect(org_membership.organization).to eq organization
      expect(org_membership.type_of_user).to eq "member"
    end

    it "returns 404 if secret is wrong" do
      expect { post "/users/join_org", params: { org_secret: "NOT SECRET" } }.
        to raise_error ActiveRecord::RecordNotFound
    end
  end

  context "when creating a new org" do
    before do
      sign_in user
      org_params = build(:organization).attributes
      org_params["profile_image"] = Rack::Test::UploadedFile.new(Rails.root.join("app", "assets", "images", "android-icon-36x36.png"), "image/jpeg")
      post "/organizations", params: { organization: org_params }
    end

    it "creates the correct organization_membership association" do
      org_membership = OrganizationMembership.first
      expect(org_membership.persisted?).to eq true
      expect(org_membership.user).to eq user
      expect(org_membership.organization).to eq Organization.last
      expect(org_membership.type_of_user).to eq "admin"
    end

    it "redirects to the proper org settings page" do
      expect(response.status).to eq 302
      expect(response.redirect_url).to include "/settings/organization/#{Organization.last.id}"
    end
  end

  context "when leaving an org" do
    let(:org_member) { create(:user, :org_member) }

    before { sign_in org_member }

    it "leaves org" do
      post "/users/leave_org"
      expect(org_member.organization_id).to eq(nil)
    end

    it "deletes the org_membership association" do
      create(:organization_membership, user_id: org_member.id, organization_id: org_member.organization_id)
      post "/users/leave_org"
      expect(OrganizationMembership.count).to eq 0
    end
  end

  context "when adding an org admin" do
    let(:org_admin) { create(:user, :org_admin) }
    let(:user2) { create(:user, organization_id: org_admin.organization_id) }

    def add_org_admin
      org_admin
      sign_in org_admin
      post "/users/add_org_admin", params: { user_id: user2.id }
    end

    it "adds org admin" do
      add_org_admin
      expect(User.last.org_admin).to eq(true)
    end

    it "creates the org_membership association" do
      add_org_admin
      org_membership = OrganizationMembership.first
      expect(org_membership.persisted?).to eq true
      expect(org_membership.user_id).to eq user2.id
      expect(org_membership.organization_id).to eq org_admin.organization_id
      expect(org_membership.type_of_user).to eq "admin"
    end

    it "raises if user not org_admin" do
      user.update(organization_id: organization.id)
      expect { post "/users/add_org_admin", params: { user_id: user2.id } }.
        to raise_error Pundit::NotAuthorizedError
    end
  end

  context "when removing an org admin" do
    let(:org_admin) { create(:user, :org_admin) }

    before { sign_in org_admin }

    it "removes org admin" do
      user2 = create(:user, organization_id: org_admin.organization_id, org_admin: true)
      post "/users/remove_org_admin", params: { user_id: user2.id }
      expect(User.last.org_admin).to eq(false)
    end

    it "updates the correct org_membership association to a member level" do
      user2 = create(:user, organization_id: org_admin.organization_id, org_admin: true)
      org_membership = create(:organization_membership, organization_id: user2.organization_id, user_id: user2.id, type_of_user: "admin")
      post "/users/remove_org_admin", params: { user_id: user2.id }
      expect(org_membership.reload.type_of_user).to eq "member"
    end

    it "remove_org_admin raises if user not org_admin" do
      user.update(organization_id: organization.id)
      user2 = create(:user, organization_id: organization.id, org_admin: true)
      expect { post "/users/remove_org_admin", params: { user_id: user2.id } }.
        to raise_error Pundit::NotAuthorizedError
    end
  end
end
