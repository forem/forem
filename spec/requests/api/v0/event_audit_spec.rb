require "rails_helper"

RSpec.describe "Event API audit logs" do
  ["application/json", "application/vnd.forem.api-v1+json"].each do |accept|
    context "with #{accept}" do
      let(:admin) { create(:user, :admin) }
      let(:api_secret) { create(:api_secret, user: admin) }
      let(:headers) { { "Accept" => accept, "api-key" => api_secret.secret } }
      let(:event) { create(:event) }
      let(:event_params) { attributes_for(:event, title: "Community challenge") }

      before { Audit::Subscribe.listen :admin_api }
      after { Audit::Subscribe.forget :admin_api }

      it "logs a creation without content or credentials" do
        post api_events_path, params: { event: event_params }, headers: headers

        expect(response).to have_http_status(:created)
        expect_audit("api_event_create", response.parsed_body["id"])
      end

      it "logs an update" do
        patch api_event_path(event.id), params: { event: { title: "Updated challenge" } }, headers: headers

        expect(response).to have_http_status(:ok)
        expect_audit("api_event_update", event.id)
      end

      it "logs a deletion" do
        delete api_event_path(event.id), headers: headers

        expect(response).to have_http_status(:no_content)
        expect(Event.exists?(event.id)).to be(false)
        expect_audit("api_event_destroy", event.id)
      end

      it "does not log an invalid creation" do
        post api_events_path, params: { event: event_params.merge(title: "") }, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(AuditLog.where(category: AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)).not_to exist
      end

      it "does not log an invalid update" do
        patch api_event_path(event.id), params: { event: { title: "" } }, headers: headers

        expect(response).to have_http_status(:unprocessable_entity)
        expect(AuditLog.where(category: AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)).not_to exist
      end

      it "does not log an unauthorized deletion" do
        admin.remove_role(:admin)
        delete api_event_path(event.id), headers: headers

        expect(response).to have_http_status(:unauthorized)
        expect(AuditLog.where(category: AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)).not_to exist
      end

      it "does not log an aborted event deletion" do
        allow(Event).to receive(:find).with(event.id.to_s).and_return(event)
        allow(event).to receive(:destroy).and_return(false)

        delete api_event_path(event.id), headers: headers

        expect(AuditLog.where(category: AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)).not_to exist
      end

      def expect_audit(action, id)
        log = AuditLog.last
        expect(log.category).to eq(AuditLog::ADMIN_API_AUDIT_LOG_CATEGORY)
        expect(log.user_id).to eq(admin.id)
        expect(log.slug).to eq(action)
        expect(log.data).to eq("action" => action, "event_id" => id)
      end
    end
  end
end
