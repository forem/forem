require "rails_helper"

RSpec.describe "UserOrganization", type: :request do
  let(:user)          { create(:user) }
  let(:organization)  { create(:organization, secret: "SECRET") }

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

    it "shows an error message if secret is invalid" do
      post "/users/join_org", params: { org_secret: "NOT SECRET" }
      expect(flash[:error]).to eq "The given organization secret was invalid."
    end

    it "correctly strips the secret of the org_secret param" do
      post "/users/join_org", params: { org_secret: organization.secret + "     " }
      expect(OrganizationMembership.exists?(user: user, organization: organization)).to eq true
    end
  end

  context "when creating a new org" do
    before do
      sign_in user
      org_params = build(:organization).attributes
      org_params["profile_image"] = Rack::Test::UploadedFile.new(Rails.root.join("app/assets/images/android-icon-36x36.png"), "image/jpeg")
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

    it "leaves org and deletes the member's organization membership" do
      org_id = org_member.organizations.first.id
      post "/users/leave_org/#{org_id}"
      expect(OrganizationMembership.exists?(user_id: org_member.id, organization_id: org_id)).to eq false
    end
  end

  context "when adding an org admin" do
    let(:org_admin) { create(:user, :org_admin) }
    let(:org_member) { create(:user, :org_member) }
    let(:org_id) { org_admin.organizations.first.id }
    let(:user2) { create(:user) }

    def add_org_admin
      org_admin
      create(:organization_membership, user_id: user2.id, organization_id: org_id)
      sign_in org_admin
      post "/users/add_org_admin", params: { user_id: user2.id, organization_id: org_id }
    end

    it "adds org admin" do
      org = org_admin.organizations.first
      add_org_admin
      expect(user2.org_admin?(org)).to eq(true)
    end

    it "creates the org_membership association" do
      add_org_admin
      org_membership = OrganizationMembership.last
      expect(org_membership.persisted?).to eq true
      expect(org_membership.user_id).to eq user2.id
      expect(org_membership.organization_id).to eq org_id
      expect(org_membership.type_of_user).to eq "admin"
    end

    it "raises not_authorized if user is not org_admin" do
      org_member_org_id = org_member.organizations.first.id
      sign_in org_member
      expect { post "/users/add_org_admin", params: { user_id: user2.id, organization_id: org_member_org_id } }.
        to raise_error Pundit::NotAuthorizedError
    end
  end

  context "when removing an org admin" do
    let(:org_admin) { create(:user, :org_admin) }
    let(:org_id) { org_admin.organizations.first.id }
    let(:second_org_admin) { create(:user, :org_admin) }

    before do
      second_org_admin.organization_memberships.update_all(organization_id: org_id)
      sign_in org_admin
    end

    it "removes org admin" do
      post "/users/remove_org_admin", params: { user_id: second_org_admin.id, organization_id: org_id }
      expect(second_org_admin.org_admin?(org_id)).to eq false
    end

    it "updates the correct org_membership association to a member level" do
      org_membership = second_org_admin.organization_memberships.first
      post "/users/remove_org_admin", params: { user_id: second_org_admin.id, organization_id: org_id }
      expect(org_membership.reload.type_of_user).to eq "member"
    end

    it "remove_org_admin raises if user not org_admin" do
      org_admin.organization_memberships.update_all(type_of_user: "member")
      expect { post "/users/remove_org_admin", params: { user_id: second_org_admin.id, organization_id: org_id } }.
        to raise_error Pundit::NotAuthorizedError
    end
  end
end
