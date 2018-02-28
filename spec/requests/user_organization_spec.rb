require "rails_helper"

RSpec.describe "UserOrganization", type: :request do
  let(:user) { create(:user) }

  before do
    @organization = create(:organization, secret: "SECRET")
    sign_in user
  end

  it "joins org with proper secret" do
    post "/users/join_org", params: {org_secret: "SECRET"}
    expect(user.organization_id).to eq(@organization.id)
  end

  it "returns 404 if secret is wrong" do
    expect { post "/users/join_org", params: {org_secret: "NOT SECRET"} }.to raise_error ActionController::RoutingError
  end

  it "leaves org" do
    post "/users/leave_org"
    expect(user.organization_id).to eq(nil)
  end

  it "adds org admin" do
    user.update(organization_id: @organization.id, org_admin: true)
    user_2 = create(:user, organization_id: @organization.id)
    post "/users/add_org_admin", params: {user_id: user_2.id}
    expect(User.last.org_admin).to eq(true)
  end

  it "raises if user not org_admin" do
    user.update(organization_id: @organization.id)
    user_2 = create(:user, organization_id: @organization.id, org_admin: true)
    expect { post "/users/add_org_admin", params: {user_id: user_2.id} }.to raise_error RuntimeError
  end

  it "removes org admin" do
    user.update(organization_id: @organization.id, org_admin: true)
    user_2 = create(:user, organization_id: @organization.id, org_admin: true)
    post "/users/remove_org_admin", params: {user_id: user_2.id}
    expect(User.last.org_admin).to eq(false)
  end

  it "raises if user not org_admin" do
    user.update(organization_id: @organization.id)
    user_2 = create(:user, organization_id: @organization.id, org_admin: true)
    expect { post "/users/remove_org_admin", params: {user_id: user_2.id} }.to raise_error RuntimeError
  end
end
