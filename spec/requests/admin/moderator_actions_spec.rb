require "rails_helper"

RSpec.describe "/admin/moderation/moderator_reactions" do
  context "when the user is not an admin" do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

    it "blocks the request" do
      expect do
        get admin_moderator_actions_path
      end.to raise_error(Pundit::NotAuthorizedError)
    end
  end

  context "when the user is a single resource admin" do
    let(:single_resource_admin) do
      create(:user, :single_resource_admin, resource: ModeratorAction)
    end

    it "renders the page" do
      sign_in single_resource_admin

      get admin_moderator_actions_path
      expect(response).to have_http_status(:ok)
    end
  end

  context "when the user is an admin" do
    let(:admin) { create(:user, :admin) }

    before do
      sign_in admin
    end

    it "does not block the request" do
      get admin_moderator_actions_path
      expect(response).to have_http_status(:ok)
    end

    it "renders the page with a user's audit log" do
      audit_log = create(
        :audit_log,
        category: AuditLog::MODERATOR_AUDIT_LOG_CATEGORY,
        user: admin,
        roles: admin.roles.pluck(:name),
      )

      get admin_moderator_actions_path

      expect(response.body).to include(admin.username)
      expect(response.body).to include(audit_log.id.to_s)
    end

    it "renders the page with an audit log not belonging to a specific user" do
      audit_log = create(
        :audit_log,
        category: AuditLog::MODERATOR_AUDIT_LOG_CATEGORY,
        user: nil,
      )

      get admin_moderator_actions_path

      expect(response.body).not_to include(admin.username)
      expect(response.body).to include(audit_log.id.to_s)
    end

    it "uses countless pagination, orders by primary key, and preloads narrow user columns" do
      other_mod = create(:user, :trusted)
      create(:audit_log, category: AuditLog::MODERATOR_AUDIT_LOG_CATEGORY, user: admin)
      create(:audit_log, category: AuditLog::MODERATOR_AUDIT_LOG_CATEGORY, user: other_mod)

      queries = []
      callback = lambda do |_name, _start, _finish, _id, payload|
        queries << payload[:sql] unless payload[:name] == "SCHEMA"
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get admin_moderator_actions_path
      end

      expect(response).to have_http_status(:ok)
      expect(queries.grep(/SELECT COUNT.*FROM "audit_logs"/i)).to be_empty

      audit_log_queries = queries.grep(/FROM "audit_logs"/i)
      expect(audit_log_queries.join(" ")).to include('ORDER BY "audit_logs"."id" DESC')
      expect(audit_log_queries.join(" ")).not_to include('"audit_logs"."roles"')

      preloaded_user_queries = queries.grep(/SELECT "users"\."id", "users"\."username" FROM "users"/i)
      expect(preloaded_user_queries.size).to eq(1)
    end

    it "filters by username using an indexed user subquery instead of a table join and supports ascending sort" do
      target_mod = create(:user, :trusted, username: "distinct_mod_action_target")
      older_log = create(:audit_log, category: AuditLog::MODERATOR_AUDIT_LOG_CATEGORY, user: target_mod)
      newer_log = create(:audit_log, category: AuditLog::MODERATOR_AUDIT_LOG_CATEGORY, user: target_mod)
      other_log = create(:audit_log, category: AuditLog::MODERATOR_AUDIT_LOG_CATEGORY, user: admin)

      queries = []
      callback = lambda do |_name, _start, _finish, _id, payload|
        queries << payload[:sql] unless payload[:name] == "SCHEMA"
      end

      ActiveSupport::Notifications.subscribed(callback, "sql.active_record") do
        get admin_moderator_actions_path, params: {
          q: { user_username_cont: "distinct_mod_action", s: "created_at asc" }
        }
      end

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        %(<td class="whitespace-nowrap">#{older_log.id}</td>),
        %(<td class="whitespace-nowrap">#{newer_log.id}</td>),
      )
      expect(response.body).not_to include(%(<td class="whitespace-nowrap">#{other_log.id}</td>))
      expect(response.body.index(%(<td class="whitespace-nowrap">#{older_log.id}</td>))).to be <
        response.body.index(%(<td class="whitespace-nowrap">#{newer_log.id}</td>))

      audit_log_queries = queries.grep(/FROM "audit_logs"/i)
      expect(audit_log_queries.join(" ")).to include("ANY(ARRAY(SELECT users.id FROM users WHERE users.username ILIKE")
      expect(audit_log_queries.join(" ")).to include('ORDER BY "audit_logs"."id" ASC')
      expect(audit_log_queries.join(" ")).not_to include('LEFT OUTER JOIN "users"')
    end
  end
end
