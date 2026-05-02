require "rails_helper"

# Validate BaseController behavior via a real subclass mounted at a temporary route.
RSpec.describe Api::V1::Admin::BaseController do
  controller_class = Class.new(described_class) do
    def index
      raise Api::Admin::ApiError.new(:test_conflict, "test", status: 409) if params[:raise] == "conflict"
      raise ActiveRecord::RecordNotFound, "User Couldn't be found" if params[:raise] == "ar_not_found"

      audit!(slug: "test_action", data: { "target_user_id" => 1 })
      render json: { ok: true }
    end
  end

  before do
    Audit::Subscribe.listen :admin_api
    stub_const("Api::V1::Admin::TestProbeController", controller_class)
    Rails.application.routes.draw do
      namespace :api do
        namespace :v1 do
          namespace :admin do
            get "test_probe", to: "test_probe#index"
          end
        end
      end
    end
  end

  after do
    Audit::Subscribe.forget :admin_api
    Rails.application.reload_routes!
  end

  context "without an api key" do
    it "returns 401" do
      get "/api/v1/admin/test_probe"
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with a non-super-admin api key" do
    it "returns 401" do
      get "/api/v1/admin/test_probe", headers: non_admin_api_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "with a super_admin api key" do
    it "renders successfully and emits an audit log" do
      expect do
        get "/api/v1/admin/test_probe", headers: admin_api_headers
      end.to change(AuditLog, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to eq("ok" => true)
      audit = AuditLog.last
      expect(audit.category).to eq("admin_api.audit.log")
      expect(audit.slug).to eq("test_action")
      expect(audit.data).to include("target_user_id" => 1)
    end

    it "renders Api::Admin::ApiError as the standard envelope" do
      get "/api/v1/admin/test_probe", params: { raise: "conflict" }, headers: admin_api_headers

      expect(response).to have_http_status(:conflict)
      expect(response.parsed_body).to eq(
        "error" => "test", "error_code" => "test_conflict", "status" => 409,
      )
    end

    it "maps RecordNotFound to a 404 with error_code" do
      get "/api/v1/admin/test_probe", params: { raise: "ar_not_found" }, headers: admin_api_headers

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body).to include("error_code" => "not_found", "status" => 404)
    end
  end
end
