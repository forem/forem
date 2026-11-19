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

  describe "PATCH /admin/permissions/sub_permissions" do
    let(:target_user) { create(:user) }
    let(:role_name) { "single_resource_admin|Billboard" }

    def grant_config(user)
      role = Role.find_by(name: "single_resource_admin", resource_type: "Billboard", resource_id: nil)
      UserRole.find_by(user_id: user.id, role_id: role.id).sub_permissions
    end

    before { target_user.add_role(:single_resource_admin, Billboard) }

    context "when signed in as an admin" do
      before { sign_in create(:user, :admin) }

      it "restricts the grant to the checked clauses", :aggregate_failures do
        patch sub_permissions_admin_permissions_path,
              params: { user_id: target_user.id, role_name: role_name, restricted: "1", allow: %w[publish] }

        expect(response).to redirect_to(admin_permissions_path)
        expect(flash[:success]).to be_present
        expect(grant_config(target_user)).to eq({ "version" => 1, "allow" => %w[publish] })
        expect(target_user.reload.sub_permission?(resource: Billboard, clause: "approve")).to be(false)
      end

      it "restricts the grant to nothing when no clause is checked" do
        patch sub_permissions_admin_permissions_path,
              params: { user_id: target_user.id, role_name: role_name, restricted: "1" }

        expect(grant_config(target_user)).to eq({ "version" => 1, "allow" => [] })
      end

      it "restores full access" do
        SubPermissions.update_grant(user: target_user, resource_type: "Billboard",
                                    sub_permissions: SubPermissions.build(allow: []))
        patch sub_permissions_admin_permissions_path,
              params: { user_id: target_user.id, role_name: role_name, restricted: "0", allow: %w[publish] }

        expect(grant_config(target_user)).to be_nil
      end

      it "refuses unknown clauses and leaves the grant unchanged", :aggregate_failures do
        patch sub_permissions_admin_permissions_path,
              params: { user_id: target_user.id, role_name: role_name, restricted: "1", allow: %w[publish everything] }

        expect(flash[:error]).to include("everything")
        expect(grant_config(target_user)).to be_nil
      end

      it "ignores a malformed allow parameter instead of storing it" do
        patch sub_permissions_admin_permissions_path,
              params: { user_id: target_user.id, role_name: role_name, restricted: "1", allow: { "0" => "publish" } }

        expect(grant_config(target_user)).to eq({ "version" => 1, "allow" => [] })
      end

      it "refuses resource types without sub-permissions" do
        target_user.add_role(:single_resource_admin, Article)
        patch sub_permissions_admin_permissions_path,
              params: { user_id: target_user.id, role_name: "single_resource_admin|Article", restricted: "1" }

        expect(flash[:error]).to be_present
      end

      it "refuses other roles and unknown users", :aggregate_failures do
        patch sub_permissions_admin_permissions_path,
              params: { user_id: target_user.id, role_name: "admin", restricted: "1" }
        expect(flash[:error]).to be_present

        patch sub_permissions_admin_permissions_path,
              params: { user_id: 0, role_name: role_name, restricted: "1" }
        expect(flash[:error]).to be_present
        expect(grant_config(target_user)).to be_nil
      end

      it "refuses a user who does not hold the grant" do
        patch sub_permissions_admin_permissions_path,
              params: { user_id: create(:user).id, role_name: role_name, restricted: "1" }

        expect(flash[:error]).to be_present
      end

      it "writes an internal audit log entry" do
        allow(Audit::Logger).to receive(:log)
        patch sub_permissions_admin_permissions_path,
              params: { user_id: target_user.id, role_name: role_name, restricted: "1", allow: %w[publish] }

        expect(Audit::Logger).to have_received(:log).with(
          :internal, anything, hash_including("action" => "update_sub_permissions", "target_user_id" => target_user.id)
        )
      end

      it "shows each Billboard admin's sub-permissions on the index", :aggregate_failures do
        SubPermissions.update_grant(user: target_user, resource_type: "Billboard",
                                    sub_permissions: SubPermissions.build(allow: %w[publish]))
        get admin_permissions_path

        expect(response.body).to include("Billboard Admin (Restricted)")
        expect(response.body).to include("data-testid=\"sub-permissions-Billboard\"")
        expect(response.body).to match(/id="allow_#{target_user.id}_Billboard_publish"[^>]*checked/)
        expect(response.body).not_to match(/id="allow_#{target_user.id}_Billboard_approve"[^>]*checked/)
      end
    end

    context "when signed in as a restricted Billboard admin" do
      before do
        restricted = create(:user, :single_resource_admin, resource: Billboard)
        SubPermissions.update_grant(user: restricted, resource_type: "Billboard",
                                    sub_permissions: SubPermissions.build(allow: []))
        sign_in restricted
      end

      it "cannot reach the permissions page to lift its own restriction" do
        expect do
          patch sub_permissions_admin_permissions_path,
                params: { user_id: target_user.id, role_name: role_name, restricted: "0" }
        end.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "the OrganizationPageManagement resource admin role" do
    let(:target_user) { create(:user) }
    let(:role_name) { "single_resource_admin|OrganizationPageManagement" }
    let(:noncanonical_role_name) { "single_resource_admin|::OrganizationPageManagement" }

    def page_management_role(user)
      user.reload.roles.where(name: "single_resource_admin", resource_type: "OrganizationPageManagement")
    end

    context "when signed in as an admin who is not a super admin" do
      before { sign_in create(:user, :admin) }

      it "refuses to grant it", :aggregate_failures do
        post grant_admin_permissions_path, params: { username: target_user.username, role_name: role_name }

        expect(response).to redirect_to(admin_permissions_path)
        expect(page_management_role(target_user)).not_to exist
        expect(flash[:error]).to be_present

        post grant_admin_permissions_path, params: { username: target_user.username, role_name: noncanonical_role_name }

        expect(response).to redirect_to(admin_permissions_path)
        expect(page_management_role(target_user)).not_to exist
        expect(flash[:error]).to be_present
      end

      it "refuses to revoke it, including via noncanonical or unscoped names", :aggregate_failures do
        target_user.add_role(:single_resource_admin, OrganizationPageManagement)

        [role_name, noncanonical_role_name, "single_resource_admin", "single_resource_admin|",
         "single_resource_admin|NonExistentResource"].each do |attempt|
          delete revoke_admin_permissions_path, params: { user_id: target_user.id, role_name: attempt }

          expect(page_management_role(target_user)).to exist
          expect(flash[:error]).to be_present
        end
      end

      it "still revokes unrelated resource admin roles without touching OrganizationPageManagement",
         :aggregate_failures do
        target_user.add_role(:single_resource_admin, OrganizationPageManagement)
        target_user.add_role(:single_resource_admin, Event)

        delete revoke_admin_permissions_path,
               params: { user_id: target_user.id, role_name: "single_resource_admin|Event" }

        expect(target_user.reload.roles.where(name: "single_resource_admin", resource_type: "Event")).not_to exist
        expect(page_management_role(target_user)).to exist
        expect(flash[:success]).to be_present
      end
    end

    context "when signed in as a Permission resource admin" do
      before { sign_in create(:user, :single_resource_admin, resource: Permission) }

      it "refuses to grant it, including via noncanonical spelling", :aggregate_failures do
        post grant_admin_permissions_path, params: { username: target_user.username, role_name: role_name }
        expect(page_management_role(target_user)).not_to exist

        post grant_admin_permissions_path, params: { username: target_user.username, role_name: noncanonical_role_name }
        expect(page_management_role(target_user)).not_to exist
      end

      it "refuses to revoke it via unscoped or noncanonical names", :aggregate_failures do
        target_user.add_role(:single_resource_admin, OrganizationPageManagement)

        [role_name, noncanonical_role_name, "single_resource_admin"].each do |attempt|
          delete revoke_admin_permissions_path, params: { user_id: target_user.id, role_name: attempt }
          expect(page_management_role(target_user)).to exist
          expect(flash[:error]).to be_present
        end
      end
    end

    context "when signed in as a super admin" do
      before { sign_in create(:user, :super_admin) }

      it "grants and revokes it", :aggregate_failures do
        post grant_admin_permissions_path, params: { username: target_user.username, role_name: role_name }
        expect(page_management_role(target_user)).to exist

        delete revoke_admin_permissions_path, params: { user_id: target_user.id, role_name: role_name }
        expect(page_management_role(target_user)).not_to exist

        post grant_admin_permissions_path, params: { username: target_user.username, role_name: noncanonical_role_name }
        expect(page_management_role(target_user)).to exist

        delete revoke_admin_permissions_path, params: { user_id: target_user.id, role_name: noncanonical_role_name }
        expect(page_management_role(target_user)).not_to exist
      end
    end
  end
end
