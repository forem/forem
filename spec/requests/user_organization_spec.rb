require "rails_helper"

RSpec.describe "UserOrganization", type: :request do
  let(:user)          { create(:user) }
  let(:organization)  { create(:organization, secret: "SECRET", approved: true) }

  def add_org_admin
    user.update(organization_id: organization.id, org_admin: true)
    user2 = create(:user, organization_id: organization.id)
    post "/users/add_org_admin", params: { user_id: user2.id }
  end

  before do
    sign_in user
  end

  it "joins org with proper secret" do
    organization
    post "/users/join_org", params: { org_secret: "SECRET" }
    expect(user.organization_id).to eq(organization.id)
  end

  it "returns 404 if secret is wrong" do
    expect { post "/users/join_org", params: { org_secret: "NOT SECRET" } }.
      to raise_error ActionController::RoutingError
  end

  it "leaves org" do
    post "/users/leave_org"
    expect(user.organization_id).to eq(nil)
  end

  it "adds org admin" do
    add_org_admin
    expect(User.last.org_admin).to eq(true)
  end

  it "adds analytics role when adding org admin if org is approved" do
    add_org_admin
    expect(User.last.has_role?(:analytics_beta_tester)).to eq(true)
  end

  it "raises if user not org_admin" do
    user.update(organization_id: organization.id)
    user2 = create(:user, organization_id: organization.id, org_admin: true)
    expect { post "/users/add_org_admin", params: { user_id: user2.id } }.
      to raise_error RuntimeError
  end

  it "removes org admin" do
    user.update(organization_id: organization.id, org_admin: true)
    user2 = create(:user, organization_id: organization.id, org_admin: true)
    post "/users/remove_org_admin", params: { user_id: user2.id }
    expect(User.last.org_admin).to eq(false)
  end

  it "remove_org_admin raises if user not org_admin" do
    user.update(organization_id: organization.id)
    user2 = create(:user, organization_id: organization.id, org_admin: true)
    expect { post "/users/remove_org_admin", params: { user_id: user2.id } }.
      to raise_error RuntimeError
  end
end
