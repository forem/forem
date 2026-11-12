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

  describe "GET /admin/permissions query efficiency and role rendering" do
    let(:super_admin) { create(:user, :super_admin) }
    let!(:admin_user) { create(:user, :admin) }
    let!(:resource_admin) { create(:user, :single_resource_admin, resource: Article) }
    let!(:regular_user) { create(:user) }

    before do
      sign_in super_admin
    end

    it "renders all admin role types without UNION or per-user role N+1 queries" do
      extra_admins = create_list(:user, 3, :admin)

      role_queries = []
      union_queries = []
      callback = lambda do |_name, _start, _finish, _id, payload|
        sql = payload[:sql].to_s
        next if payload[:name] == "SCHEMA" || sql.include?("SAVEPOINT")

        role_queries << sql if sql.include?('FROM "roles"') && sql.include?('"users_roles"."user_id"')
        union_queries << sql if sql.include?("UNION")
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get admin_permissions_path
      end

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("@#{super_admin.username}", "Super Admin")
      expect(response.body).to include("@#{admin_user.username}", "Admin")
      expect(response.body).to include("@#{resource_admin.username}", "Article Admin")
      extra_admins.each do |extra_admin|
        expect(response.body).to include("@#{extra_admin.username}")
      end
      expect(response.body).not_to include("@#{regular_user.username}")
      expect(union_queries).to be_empty
      # 1 role check for current_user authorization + 1 batch preload for all listed @users
      expect(role_queries.size).to be <= 2
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
      post grant_admin_permissions_path,
           params: { username: target_user.username, role_name: "single_resource_admin|Event" }
      expect(response).to redirect_to(admin_permissions_path)
      expect(target_user.reload.roles.where(name: "single_resource_admin", resource_type: "Event")).to exist
      expect(flash[:success]).to be_present
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
      delete revoke_admin_permissions_path,
             params: { user_id: target_user.id, role_name: "single_resource_admin|Event" }
      expect(response).to redirect_to(admin_permissions_path)
      expect(target_user.reload.roles.where(name: "single_resource_admin", resource_type: "Event")).not_to exist
      expect(flash[:success]).to be_present
    end
  end
end
