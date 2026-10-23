require "rails_helper"

RSpec.describe "/admin/permissions" do
  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "blocks the request" do
      expect do
        get admin_permissions_path
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when the user is a super admin" do
    let(:super_admin) { create(:user, :super_admin) }

    before do
      sign_in super_admin
      get admin_permissions_path
    end

    it "allows the request" do
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Permission) }

    before do
      sign_in single_resource_admin
      get admin_permissions_path
    end

    it "allows the request" do
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user is the wrong single resource admin" do
    let(:single_resource_admin) { create(:user, :single_resource_admin, resource: Article) }

    before do
      sign_in single_resource_admin
    end

    it "blocks the request" do
      expect do
        get admin_permissions_path
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  describe "POST /admin/permissions/grant" do
    let(:super_admin) { create(:user, :super_admin) }
    let(:target_user) { create(:user) }

    before do
      sign_in super_admin
    end

    it "grants the specified role to the user" do
      post grant_admin_permissions_path, params: { username: target_user.username, role_name: "admin" }
      expect(response).to redirect_to(admin_permissions_path)
      expect(target_user.reload.roles.pluck(:name)).to include("admin")
      expect(flash[:success]).to be_present
    end

    it "strips @ from username and grants the role" do
      post grant_admin_permissions_path, params: { username: "@#{target_user.username}", role_name: "admin" }
      expect(target_user.reload.roles.pluck(:name)).to include("admin")
    end

    it "fails gracefully with invalid username" do
      post grant_admin_permissions_path, params: { username: "does_not_exist", role_name: "admin" }
      expect(response).to redirect_to(admin_permissions_path)
      expect(flash[:error]).to be_present
    end

    it "fails gracefully with invalid role" do
      post grant_admin_permissions_path, params: { username: target_user.username, role_name: "invalid_role" }
      expect(target_user.reload.roles.pluck(:name)).not_to include("invalid_role")
      expect(flash[:error]).to be_present
    end

    it "grants a single resource admin role to the user" do
      post grant_admin_permissions_path, params: { username: target_user.username, role_name: "single_resource_admin|Event" }
      expect(response).to redirect_to(admin_permissions_path)
      expect(target_user.reload.roles.where(name: "single_resource_admin", resource_type: "Event")).to exist
      expect(flash[:success]).to be_present
    end

    it "grants single resource admin on a specific role, creating the role record if needed", :aggregate_failures do
      expect(Role.global.find_by(name: "base_subscriber")).to be_nil

      post grant_admin_permissions_path,
           params: { username: target_user.username, role_name: "single_resource_admin|Role|base_subscriber" }

      expect(response).to redirect_to(admin_permissions_path)
      base_subscriber_role = Role.global.find_by(name: "base_subscriber")
      expect(base_subscriber_role).to be_present
      expect(target_user.reload.single_resource_admin_for?(base_subscriber_role)).to be true
      expect(target_user.base_subscriber?).to be false
      expect(flash[:success]).to be_present
    end

    it "uses the existing role record" do
      existing_role = Role.global.find_or_create_by!(name: "base_subscriber")

      expect do
        post grant_admin_permissions_path,
             params: { username: target_user.username, role_name: "single_resource_admin|Role|base_subscriber" }
      end.to change(Role, :count).by(1) # only the scoped single_resource_admin role

      expect(target_user.reload.roles.find_by(name: "single_resource_admin").resource).to eq(existing_role)
    end

    it "rejects a role scope that is not allowed", :aggregate_failures do
      post grant_admin_permissions_path,
           params: { username: target_user.username, role_name: "single_resource_admin|Role|trusted" }

      expect(flash[:error]).to be_present
      expect(target_user.reload.roles).to be_empty
    end

    it "rejects a class-level role scope", :aggregate_failures do
      post grant_admin_permissions_path,
           params: { username: target_user.username, role_name: "single_resource_admin|Role" }

      expect(flash[:error]).to be_present
      expect(target_user.reload.roles).to be_empty
    end
  end

  describe "GET /admin/permissions with a role-scoped resource admin" do
    let(:super_admin) { create(:user, :super_admin) }
    let(:scoped_admin) { create(:user) }

    before do
      scoped_admin.add_role(:single_resource_admin, Role.global.find_or_create_by!(name: "base_subscriber"))
      sign_in super_admin
    end

    it "lists the user with the scoped role and offers it in the grant form", :aggregate_failures do
      get admin_permissions_path

      expect(response.body).to include("@#{scoped_admin.username}")
      expect(response.body).to include("Role Admin: base_subscriber")
      expect(response.body).to include("single_resource_admin|Role|base_subscriber")
      expect(response.body).to include("Resource Admin: Role base_subscriber")
    end
  end

  describe "DELETE /admin/permissions/revoke" do
    let(:super_admin) { create(:user, :super_admin) }
    let(:target_user) { create(:user, :admin) }

    before do
      sign_in super_admin
    end

    it "revokes the specified role from the user" do
      delete revoke_admin_permissions_path, params: { user_id: target_user.id, role_name: "admin" }
      expect(response).to redirect_to(admin_permissions_path)
      expect(target_user.reload.roles.pluck(:name)).not_to include("admin")
      expect(flash[:success]).to be_present
    end

    it "fails gracefully with invalid role" do
      delete revoke_admin_permissions_path, params: { user_id: target_user.id, role_name: "invalid_role" }
      expect(response).to redirect_to(admin_permissions_path)
      expect(flash[:error]).to be_present
    end

    it "revokes a single resource admin role from the user" do
      target_user.add_role(:single_resource_admin, Event)
      delete revoke_admin_permissions_path, params: { user_id: target_user.id, role_name: "single_resource_admin|Event" }
      expect(response).to redirect_to(admin_permissions_path)
      expect(target_user.reload.roles.where(name: "single_resource_admin", resource_type: "Event")).not_to exist
      expect(flash[:success]).to be_present
    end

    it "revokes single resource admin on a specific role only", :aggregate_failures do
      base_subscriber_role = Role.global.find_or_create_by!(name: "base_subscriber")
      target_user.add_role(:single_resource_admin, base_subscriber_role)
      target_user.add_role(:single_resource_admin, Event)

      delete revoke_admin_permissions_path,
             params: { user_id: target_user.id, role_name: "single_resource_admin|Role|base_subscriber" }

      expect(response).to redirect_to(admin_permissions_path)
      target_user.reload
      expect(target_user.single_resource_admin_for?(base_subscriber_role)).to be false
      expect(target_user.roles.where(name: "single_resource_admin", resource_type: "Event")).to exist
      expect(target_user.admin?).to be true
      expect(flash[:success]).to be_present
    end
  end
end
