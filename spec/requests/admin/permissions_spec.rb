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
  end
end
