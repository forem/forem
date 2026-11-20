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

    it "shows tech_admin users and supports searching and filtering by role and resource", :aggregate_failures do
      tech_admin = create(:user, name: "Tech Person", username: "tech_operator")
      tech_admin.add_role(:tech_admin)

      restricted_bb = create(:user, :single_resource_admin, resource: Billboard, username: "bb_bot")
      SubPermissions.update_grant(user: restricted_bb, resource_type: "Billboard",
                                  sub_permissions: SubPermissions.build(allow: %w[publish]))

      get admin_permissions_path
      expect(response.body).to include("@tech_operator", "Tech Admin")
      expect(response.body).to include("@bb_bot", "Billboard Admin (Restricted)")

      get admin_permissions_path, params: { search: "@tech_operator" }
      expect(response.body).to include("@tech_operator")
      expect(response.body).not_to include("@#{admin_user.username}")

      get admin_permissions_path, params: { role_filter: "restricted" }
      expect(response.body).to include("@bb_bot")
      expect(response.body).not_to include("@#{resource_admin.username}")
      expect(response.body).not_to include("@#{admin_user.username}")

      get admin_permissions_path, params: { role_filter: "single_resource_admin", resource_filter: "Article" }
      expect(response.body).to include("@#{resource_admin.username}")
      expect(response.body).not_to include("@bb_bot")
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

    it "writes an internal audit log entry" do
      allow(Audit::Logger).to receive(:log)
      post grant_admin_permissions_path, params: { username: target_user.username, role_name: "admin" }

      expect(Audit::Logger).to have_received(:log).with(
        :internal, super_admin, hash_including("action" => "grant_role", "target_user_id" => target_user.id,
                                               "role_name" => "admin", "resource_type" => nil)
      )
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

    it "atomically grants a restricted Billboard admin role with selected sub-permissions", :aggregate_failures do
      allow(Audit::Logger).to receive(:log)

      post grant_admin_permissions_path,
           params: {
             username: target_user.username,
             role_name: "single_resource_admin|Billboard",
             restricted: "1",
             allow: %w[publish]
           }

      expect(response).to redirect_to(admin_permissions_path)
      expect(flash[:success]).to be_present
      expect(target_user.reload.single_resource_admin_for?(Billboard)).to be(true)
      expect(target_user.sub_permission?(resource: Billboard, clause: "publish")).to be(true)
      expect(target_user.sub_permission?(resource: Billboard, clause: "approve")).to be(false)
      expect(Audit::Logger).to have_received(:log).with(
        :internal, anything, hash_including("action" => "update_sub_permissions", "target_user_id" => target_user.id)
      )
    end

    it "atomically grants a draft-only restricted Billboard admin when no clauses are checked", :aggregate_failures do
      post grant_admin_permissions_path,
           params: {
             username: target_user.username,
             role_name: "single_resource_admin|Billboard",
             restricted: "1"
           }

      expect(response).to redirect_to(admin_permissions_path)
      expect(target_user.reload.single_resource_admin_for?(Billboard)).to be(true)
      expect(target_user.sub_permission?(resource: Billboard, clause: "publish")).to be(false)
      expect(target_user.sub_permission?(resource: Billboard, clause: "approve")).to be(false)
      expect(target_user.sub_permission?(resource: Billboard, clause: "modify_approved")).to be(false)
    end

    it "does not grant the role when restricted sub-permissions contain an unknown clause", :aggregate_failures do
      post grant_admin_permissions_path,
           params: {
             username: target_user.username,
             role_name: "single_resource_admin|Billboard",
             restricted: "1",
             allow: %w[publish unknown_clause]
           }

      expect(response).to redirect_to(admin_permissions_path)
      expect(flash[:error]).to include("unknown_clause")
      expect(target_user.reload.single_resource_admin_for?(Billboard)).to be(false)
    end

    it "preserves active filter params on redirect when return filters are supplied" do
      post grant_admin_permissions_path,
           params: {
             username: target_user.username,
             role_name: "admin",
             return_role_filter: "admin",
             return_search: target_user.username
           }

      expect(response).to redirect_to(admin_permissions_path(role_filter: "admin", search: target_user.username))
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

    it "writes an internal audit log entry" do
      target_user.add_role(:single_resource_admin, Event)
      allow(Audit::Logger).to receive(:log)
      delete revoke_admin_permissions_path,
             params: { user_id: target_user.id, role_name: "single_resource_admin|Event" }

      expect(Audit::Logger).to have_received(:log).with(
        :internal, super_admin, hash_including("action" => "revoke_role", "target_user_id" => target_user.id,
                                               "role_name" => "single_resource_admin", "resource_type" => "Event")
      )
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

  describe "global admin roles" do
    let(:target_user) { create(:user) }

    context "when signed in as an admin who is not a super admin" do
      before { sign_in create(:user, :admin) }

      it "refuses to grant them", :aggregate_failures do
        %w[admin super_admin tech_admin].each do |role_name|
          post grant_admin_permissions_path, params: { username: target_user.username, role_name: role_name }

          expect(response).to redirect_to(admin_permissions_path)
          expect(flash[:error]).to be_present
          expect(target_user.reload.roles.pluck(:name)).not_to include(role_name)
        end
      end

      it "refuses to revoke them", :aggregate_failures do
        target_user.add_role(:admin)

        delete revoke_admin_permissions_path, params: { user_id: target_user.id, role_name: "admin" }

        expect(response).to redirect_to(admin_permissions_path)
        expect(flash[:error]).to be_present
        expect(target_user.reload.roles.pluck(:name)).to include("admin")
      end

      it "still grants a single resource admin role" do
        post grant_admin_permissions_path,
             params: { username: target_user.username, role_name: "single_resource_admin|Event" }

        expect(target_user.reload.roles.where(name: "single_resource_admin", resource_type: "Event")).to exist
      end
    end

    context "when signed in as a Permission resource admin" do
      before { sign_in create(:user, :single_resource_admin, resource: Permission) }

      it "refuses to grant them" do
        post grant_admin_permissions_path, params: { username: target_user.username, role_name: "super_admin" }

        expect(target_user.reload.roles.pluck(:name)).not_to include("super_admin")
      end
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

      it "refuses a missing or unknown mode instead of restoring full access", :aggregate_failures do
        SubPermissions.update_grant(user: target_user, resource_type: "Billboard",
                                    sub_permissions: SubPermissions.build(allow: []))

        [nil, "", "true", "restricted"].each do |mode|
          params = { user_id: target_user.id, role_name: role_name, allow: %w[publish] }
          params[:restricted] = mode unless mode.nil?
          patch sub_permissions_admin_permissions_path, params: params

          expect(flash[:error]).to be_present
          expect(grant_config(target_user)).to eq({ "version" => 1, "allow" => [] })
        end
      end

      {
        "a JSON null" => "'null'::jsonb",
        "a JSON false" => "'false'::jsonb",
        "a future version" => %q('{"version": 2, "allow": ["approve"]}'::jsonb)
      }.each do |description, sql|
        it "shows an unreadable config (#{description}) as restricted, and saving it keeps it restricted",
           :aggregate_failures do
          UserRole.where(user_id: target_user.id).update_all("sub_permissions = #{sql}")
          get admin_permissions_path

          form = Nokogiri::HTML(response.body).css("form").detect do |candidate|
            candidate.at_css("input[name='user_id'][value='#{target_user.id}']")
          end

          expect(response.body).to include("Billboard Admin (Restricted)")
          expect(form.at_css("input[name='restricted'][value='1']")["checked"]).to be_present
          expect(form.at_css("input[name='restricted'][value='0']")["checked"]).to be_nil
          expect(form.css("input[name='allow[]'][checked]")).to be_empty

          patch sub_permissions_admin_permissions_path,
                params: { user_id: target_user.id, role_name: role_name, restricted: "1" }

          expect(grant_config(target_user)).to eq({ "version" => 1, "allow" => [] })
          expect(target_user.reload.sub_permission?(resource: Billboard, clause: "approve")).to be(false)
        end
      end

      it "shows no editor for a user whose only Billboard role is scoped to one record" do
        record_admin = create(:user)
        record_admin.add_role(:single_resource_admin, create(:billboard))
        get admin_permissions_path

        row = Nokogiri::HTML(response.body).at_css("[data-testid='permission-member-row-#{record_admin.id}']")

        expect(row).to be_present
        expect(row.css("[data-testid='sub-permissions-Billboard']")).to be_empty
      end

      it "shows one editor, for the class-wide grant, to a user with record and class-wide roles" do
        target_user.add_role(:single_resource_admin, create(:billboard))
        get admin_permissions_path

        row = Nokogiri::HTML(response.body).at_css("[data-testid='permission-member-row-#{target_user.id}']")

        expect(row.css("[data-testid='sub-permissions-Billboard']").size).to eq(1)
        expect(row.css("#allow_#{target_user.id}_Billboard_approve").size).to eq(1)
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

  describe "global platform admin roles (super_admin, admin, tech_admin)" do
    let(:target_user) { create(:user) }

    context "when signed in as a regular admin who is not a super admin" do
      let(:regular_admin) { create(:user, :admin) }

      before { sign_in regular_admin }

      it "refuses to grant super_admin, admin, or tech_admin to self or another user", :aggregate_failures do
        %w[super_admin admin tech_admin].each do |role_name|
          post grant_admin_permissions_path, params: { username: regular_admin.username, role_name: role_name }
          expect(response).to redirect_to(admin_permissions_path)
          expect(flash[:error]).to include("Only super admins")

          post grant_admin_permissions_path, params: { username: target_user.username, role_name: role_name }
          expect(response).to redirect_to(admin_permissions_path)
          expect(flash[:error]).to include("Only super admins")
          expect(target_user.reload.roles.where(name: role_name)).not_to exist
        end

        expect(regular_admin.reload.super_admin?).to be(false)
        expect(regular_admin.tech_admin?).to be(false)
      end

      it "refuses to revoke super_admin, admin, or tech_admin from another user", :aggregate_failures do
        super_admin_target = create(:user, :super_admin)
        super_admin_target.add_role(:admin)
        super_admin_target.add_role(:tech_admin)

        %w[super_admin admin tech_admin].each do |role_name|
          delete revoke_admin_permissions_path, params: { user_id: super_admin_target.id, role_name: role_name }
          expect(response).to redirect_to(admin_permissions_path)
          expect(flash[:error]).to include("Only super admins")
          expect(super_admin_target.reload.roles.where(name: role_name)).to exist
        end
      end

      it "hides platform roles from grant selects and locks revoke buttons on the index", :aggregate_failures do
        super_admin_target = create(:user, :super_admin)
        super_admin_target.add_role(:tech_admin)

        get admin_permissions_path
        doc = Nokogiri::HTML(response.body)

        option_values = doc.css("select[name='role_name'] option").pluck("value")
        expect(option_values).not_to include("super_admin", "admin", "tech_admin")
        expect(option_values).to include("single_resource_admin|Event")

        revoke_actions = doc.css("form.admin-role-pill__revoke-form").pluck("action")
        expect(revoke_actions.none? { |action| action.include?("role_name=super_admin") }).to be(true)
        expect(revoke_actions.none? { |action| action.include?("role_name=admin") }).to be(true)
        expect(revoke_actions.none? { |action| action.include?("role_name=tech_admin") }).to be(true)
      end

      it "still grants and revokes ordinary single resource admin roles", :aggregate_failures do
        post grant_admin_permissions_path,
             params: { username: target_user.username, role_name: "single_resource_admin|Event" }
        expect(target_user.reload.single_resource_admin_for?(Event)).to be(true)

        delete revoke_admin_permissions_path,
               params: { user_id: target_user.id, role_name: "single_resource_admin|Event" }
        expect(target_user.reload.single_resource_admin_for?(Event)).to be(false)
      end
    end

    context "when signed in as a Permission resource admin" do
      let(:permission_admin) { create(:user, :single_resource_admin, resource: Permission) }

      before { sign_in permission_admin }

      it "refuses to grant super_admin, admin, or tech_admin to self or another user", :aggregate_failures do
        %w[super_admin admin tech_admin].each do |role_name|
          post grant_admin_permissions_path, params: { username: permission_admin.username, role_name: role_name }
          expect(response).to redirect_to(admin_permissions_path)
          expect(flash[:error]).to include("Only super admins")
          expect(permission_admin.reload.roles.where(name: role_name)).not_to exist

          post grant_admin_permissions_path, params: { username: target_user.username, role_name: role_name }
          expect(response).to redirect_to(admin_permissions_path)
          expect(flash[:error]).to include("Only super admins")
          expect(target_user.reload.roles.where(name: role_name)).not_to exist
        end
      end

      it "refuses to revoke super_admin, admin, or tech_admin", :aggregate_failures do
        super_admin_target = create(:user, :super_admin)
        super_admin_target.add_role(:admin)
        super_admin_target.add_role(:tech_admin)

        %w[super_admin admin tech_admin].each do |role_name|
          delete revoke_admin_permissions_path, params: { user_id: super_admin_target.id, role_name: role_name }
          expect(response).to redirect_to(admin_permissions_path)
          expect(flash[:error]).to include("Only super admins")
          expect(super_admin_target.reload.roles.where(name: role_name)).to exist
        end
      end
    end

    context "when signed in as a super admin" do
      before { sign_in create(:user, :super_admin) }

      it "grants and revokes super_admin, admin, and tech_admin", :aggregate_failures do
        %w[super_admin admin tech_admin].each do |role_name|
          post grant_admin_permissions_path, params: { username: target_user.username, role_name: role_name }
          expect(response).to redirect_to(admin_permissions_path)
          expect(flash[:success]).to be_present
          expect(target_user.reload.roles.where(name: role_name)).to exist

          delete revoke_admin_permissions_path, params: { user_id: target_user.id, role_name: role_name }
          expect(response).to redirect_to(admin_permissions_path)
          expect(flash[:success]).to be_present
          expect(target_user.reload.roles.where(name: role_name)).not_to exist
        end
      end
    end
  end
end
