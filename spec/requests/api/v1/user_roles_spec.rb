require "rails_helper"

RSpec.describe "Api::V1::UserRoles" do
  let(:api_secret) { create(:api_secret) }
  let(:headers) { { "Accept" => "application/vnd.forem.api-v1+json" } }
  let(:auth_headers) { headers.merge({ "api-key" => api_secret.secret }) }
  let(:listener) { :admin_api }

  describe "PUT /api/users/:id/suspend", :aggregate_failures do
    let(:target_user) { create(:user) }
    let(:payload) { { note: "Violated CoC despite multiple warnings" } }

    before { Audit::Subscribe.listen listener }
    after { Audit::Subscribe.forget listener }

    context "when unauthenticated" do
      it "returns unauthorized" do
        put api_user_add_role_path(id: target_user.id, role: "suspended"),
            params: payload,
            headers: headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when unauthorized" do
      it "returns unauthorized if api key is invalid" do
        put api_user_add_role_path(id: target_user.id, role: "suspended"),
            params: payload,
            headers: headers.merge({ "api-key" => "invalid api key" })

        expect(response).to have_http_status(:unauthorized)
      end

      it "returns unauthorized if api key belongs to non-admin user" do
        put api_user_add_role_path(id: target_user.id, role: "suspended"),
            params: payload,
            headers: headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when request is authenticated" do
      before { api_secret.user.add_role(:super_admin) }

      it "is successful in suspending a user", :aggregate_failures do
        expect do
          put api_user_add_role_path(id: target_user.id, role: "suspended"),
              params: payload,
              headers: auth_headers

          expect(response).to have_http_status(:no_content)
          expect(target_user.reload.suspended?).to be true
          expect(Note.last.content).to eq(payload[:note])
        end.to change(Note, :count).by(1)
      end

      it "creates an audit log of the action taken" do
        put api_user_add_role_path(id: target_user.id, role: "suspended"),
            params: payload,
            headers: auth_headers

        log = AuditLog.last
        expect(log.category).to eq(AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)
        expect(log.data["action"]).to eq("api_user_suspend")
        expect(log.data["target_user_id"]).to eq(target_user.id)
        expect(log.user_id).to eq(api_secret.user.id)
      end
    end
  end

  describe "PUT /api/users/:id/limited", :aggregate_failures do
    let(:target_user) { create(:user) }

    before { Audit::Subscribe.listen listener }
    after { Audit::Subscribe.forget listener }

    context "when unauthenticated" do
      it "returns unauthorized" do
        put api_user_add_role_path(target_user, "limited"), headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when unauthorized" do
      it "returns unauthorized if api key is invalid" do
        put api_user_add_role_path(target_user, "limited"),
            headers: headers.merge({ "api-key" => "invalid api key" })

        expect(response).to have_http_status(:unauthorized)
      end

      # Setup via let(:api_secret) creates a user with no admin privileges
      it "returns unauthorized if api key belongs to non-admin user" do
        put api_user_add_role_path(target_user, "limited"), headers: auth_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when request is authenticated" do
      before { api_secret.user.add_role(:super_admin) }

      it "is successful in limiting a user", :aggregate_failures do
        expect do
          put api_user_add_role_path(target_user, "limited"), headers: auth_headers

          expect(response).to have_http_status(:no_content)
          expect(target_user.reload.limited?).to be true
          expect(Note.last.content).to match(/username\d+ updated username\d+/)
        end.to change(Note, :count).by(1)
      end

      it "creates an audit log of the action taken" do
        put api_user_add_role_path(target_user, "limited"), headers: auth_headers

        log = AuditLog.last
        expect(log.category).to eq(AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)
        expect(log.data["action"]).to eq("api_user_limited")
        expect(log.data["target_user_id"]).to eq(target_user.id)
        expect(log.user_id).to eq(api_secret.user.id)
      end
    end
  end

  describe "DELETE /api/users/:id/limited", :aggregate_failures do
    let(:target_user) { create(:user, :limited) }

    before { Audit::Subscribe.listen listener }
    after { Audit::Subscribe.forget listener }

    context "when unauthenticated" do
      it "returns unauthorized" do
        delete api_user_remove_role_path(target_user, "limited"), headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when unauthorized" do
      it "returns unauthorized if api key is invalid" do
        delete api_user_remove_role_path(target_user, "limited"),
               headers: headers.merge({ "api-key" => "invalid api key" })

        expect(response).to have_http_status(:unauthorized)
      end

      # Setup via let(:api_secret) creates a user with no admin privileges
      it "returns unauthorized if api key belongs to non-admin user" do
        delete api_user_remove_role_path(target_user, "limited"), headers: auth_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when request is authenticated" do
      before { api_secret.user.add_role(:super_admin) }

      it "is successful in limiting a user", :aggregate_failures do
        expect do
          delete api_user_remove_role_path(target_user, "limited"), headers: auth_headers

          expect(response).to have_http_status(:no_content)
          expect(target_user.reload.limited?).to be false
          expect(target_user.roles).to eq([])
          expect(Note.last.content).to match(/username\d+ updated username\d+/)
        end.to change(Note, :count).by(1)
      end

      it "creates an audit log of the action taken" do
        delete api_user_remove_role_path(target_user, "limited"), headers: auth_headers

        log = AuditLog.last
        expect(log.category).to eq(AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)
        expect(log.data["action"]).to eq("api_user_remove_limited")
        expect(log.data["target_user_id"]).to eq(target_user.id)
        expect(log.user_id).to eq(api_secret.user.id)
      end
    end
  end

  describe "PUT /api/users/:id/spam", :aggregate_failures do
    let(:target_user) { create(:user) }

    before { Audit::Subscribe.listen listener }
    after { Audit::Subscribe.forget listener }

    context "when unauthenticated" do
      it "returns unauthorized" do
        put api_user_add_role_path(target_user, "spam"), headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when unauthorized" do
      it "returns unauthorized if api key is invalid" do
        put api_user_add_role_path(target_user, "spam"),
            headers: headers.merge({ "api-key" => "invalid api key" })

        expect(response).to have_http_status(:unauthorized)
      end

      # Setup via let(:api_secret) creates a user with no admin privileges
      it "returns unauthorized if api key belongs to non-admin user" do
        put api_user_add_role_path(target_user, "spam"), headers: auth_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when request is authenticated" do
      before { api_secret.user.add_role(:super_admin) }

      it "is successful in limiting a user", :aggregate_failures do
        expect do
          put api_user_add_role_path(target_user, "spam"), headers: auth_headers

          expect(response).to have_http_status(:no_content)
          expect(target_user.reload.spam?).to be true
          expect(Note.last.content).to match(/username\d+ updated username\d+/)
        end.to change(Note, :count).by(1)
      end

      it "creates an audit log of the action taken" do
        put api_user_add_role_path(target_user, "spam"), headers: auth_headers

        log = AuditLog.last
        expect(log.category).to eq(AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)
        expect(log.data["action"]).to eq("api_user_spam")
        expect(log.data["target_user_id"]).to eq(target_user.id)
        expect(log.user_id).to eq(api_secret.user.id)
      end
    end
  end

  describe "DELETE /api/users/:id/spam", :aggregate_failures do
    let(:target_user) { create(:user, :spam) }

    before { Audit::Subscribe.listen listener }
    after { Audit::Subscribe.forget listener }

    context "when unauthenticated" do
      it "returns unauthorized" do
        delete api_user_remove_role_path(target_user, "spam"), headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when unauthorized" do
      it "returns unauthorized if api key is invalid" do
        delete api_user_remove_role_path(target_user, "spam"),
               headers: headers.merge({ "api-key" => "invalid api key" })

        expect(response).to have_http_status(:unauthorized)
      end

      # Setup via let(:api_secret) creates a user with no admin privileges
      it "returns unauthorized if api key belongs to non-admin user" do
        delete api_user_remove_role_path(target_user, "spam"), headers: auth_headers

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when request is authenticated" do
      before { api_secret.user.add_role(:super_admin) }

      it "is successful in adding the spam role to a user", :aggregate_failures do
        expect do
          delete api_user_remove_role_path(target_user, "spam"), headers: auth_headers

          expect(response).to have_http_status(:no_content)
          expect(target_user.reload.spam?).to be false
          expect(target_user.roles).to eq([])
          expect(Note.last.content).to match(/username\d+ updated username\d+/)
        end.to change(Note, :count).by(1)
      end

      it "creates an audit log of the action taken" do
        delete api_user_remove_role_path(target_user, "spam"), headers: auth_headers

        log = AuditLog.last
        expect(log.category).to eq(AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)
        expect(log.data["action"]).to eq("api_user_remove_spam")
        expect(log.data["target_user_id"]).to eq(target_user.id)
        expect(log.user_id).to eq(api_secret.user.id)
      end
    end
  end
end
