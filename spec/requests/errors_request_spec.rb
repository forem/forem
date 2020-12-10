require "rails_helper"

RSpec.describe "Errors", type: :request do
  describe "GET /404" do
    it "returns not found error" do
      get errors_not_found_path

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /422" do
    it "returns unprocessable entity error" do
      get errors_unprocessable_entity_path

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /500" do
    it "returns internal server error" do
      get errors_internal_server_error_path

      expect(response).to have_http_status(:internal_server_error)
    end

    it "does not include the prompt to report on Forem GitHub" do
      allow(SiteConfig).to receive(:app_domain).and_return("example.com")

      get errors_internal_server_error_path

      expect(response).to have_http_status(:internal_server_error)
      expect(response.body).not_to include("github.com/forem/forem/issues")
    end

    it "includes the prompt to report on Forem GitHub for DEV" do
      allow(SiteConfig).to receive(:app_domain).and_return("dev.to")

      get errors_internal_server_error_path

      expect(response).to have_http_status(:internal_server_error)
      expect(response.body).to include("github.com/forem/forem/issues")
    end
  end

  describe "GET /503" do
    it "returns service unavailable error" do
      get errors_service_unavailable_path

      expect(response).to have_http_status(:service_unavailable)
    end
  end
end
