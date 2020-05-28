require "rails_helper"

RSpec.describe "HealthCheck", type: :request do
  let(:token) { "secret" }
  let(:headers) { { "health-check-token" => token } }

  before { SiteConfig.health_check_token = token }

  context "without a token" do
    it "returns an unauthorized request" do
      get app_api_health_checks_path
      expect(response.status).to eq(401)
    end
  end

  describe "GET /api/health_checks/app" do
    it "returns json success" do
      get app_api_health_checks_path, headers: headers
      expect(response.status).to eq(200)
      expect(response.parsed_body["message"]).to eq("App is up!")
    end
  end

  describe "GET /api/health_checks/search" do
    it "returns json success if ping succeeds" do
      get search_api_health_checks_path, headers: headers
      expect(response.status).to eq(200)
      expect(response.parsed_body["message"]).to eq("Search ping succeeded!")
    end

    it "returns json failure if ping fails" do
      allow(Search::Client).to receive(:ping).and_return(false)
      get search_api_health_checks_path, headers: headers
      expect(response.status).to eq(500)
      expect(response.parsed_body["message"]).to eq("Search ping failed!")
    end
  end

  describe "GET /api/health_checks/database" do
    it "returns json success if connection check succeeds" do
      get database_api_health_checks_path, headers: headers
      expect(response.status).to eq(200)
      expect(response.parsed_body["message"]).to eq("Database connected")
    end

    it "returns json failure if connection check fails" do
      allow(ActiveRecord::Base).to receive(:connected?).and_return(false)
      get database_api_health_checks_path, headers: headers
      expect(response.status).to eq(500)
      expect(response.parsed_body["message"]).to eq("Database NOT connected!")
    end
  end
end
