require "rails_helper"

RSpec.describe "HealthCheck", type: :request do
  let(:token) { "secret" }
  let(:headers) { { "health-check-token" => token } }

  before { allow(Settings::General).to receive(:health_check_token).and_return(token) }

  context "without a token" do
    it "returns an unauthorized request" do
      allow_any_instance_of(ActionDispatch::Request).to receive(:remote_addr).and_return("0.0.0.0") # rubocop:disable RSpec/AnyInstance
      get app_api_health_checks_path
      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe "GET /api/health_checks/app" do
    it "returns json success" do
      get app_api_health_checks_path, headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["message"]).to eq("App is up!")
    end
  end

  describe "GET /api/health_checks/database" do
    it "returns json success if connection check succeeds" do
      get database_api_health_checks_path, headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["message"]).to eq("Database connected")
    end

    it "returns json failure if connection check fails" do
      allow(ActiveRecord::Base).to receive(:connected?).and_return(false)
      get database_api_health_checks_path, headers: headers
      expect(response).to have_http_status(:internal_server_error)
      expect(response.parsed_body["message"]).to eq("Database NOT connected!")
    end
  end

  describe "GET /api/health_checks/cache" do
    it "returns json success if connection check succeeds" do
      get cache_api_health_checks_path, headers: headers
      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["message"]).to eq("Redis connected")
    end

    it "returns json failure if connection check fails" do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("REDIS_SESSIONS_URL").and_return("redis://redis:6379")

      redis_obj = Redis.new
      allow(Redis).to receive(:new).and_return(redis_obj)
      allow(redis_obj).to receive(:ping).and_return("fail")
      get cache_api_health_checks_path, headers: headers
      expect(response).to have_http_status(:internal_server_error)
      expect(response.parsed_body["message"]).to eq("Redis NOT connected!")
    end
  end
end
