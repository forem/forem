require "rails_helper"

RSpec.describe "HealthCheck", type: :request do
  describe "GET /health_check" do
    it "returns json success" do
      get health_check_path
      expect(response.status).to eq(200)
      expect(response.parsed_body["message"]).to eq("App is up!")
    end
  end

  describe "GET /search_health_check" do
    it "returns json success if ping succeeds" do
      get search_health_check_path
      expect(response.status).to eq(200)
      expect(response.parsed_body["message"]).to eq("Search ping succeeded!")
    end

    it "returns json failure if ping fails" do
      allow(Search::Client).to receive(:ping).and_return(false)
      get search_health_check_path
      expect(response.status).to eq(500)
      expect(response.parsed_body["message"]).to eq("Search ping failed!")
    end
  end

  describe "GET /database_health_check" do
    it "returns json success if connection check succeeds" do
      get database_health_check_path
      expect(response.status).to eq(200)
      expect(response.parsed_body["message"]).to eq("Database connected")
    end

    it "returns json failure if connection check fails" do
      allow(ActiveRecord::Base).to receive(:connected?).and_return(false)
      get database_health_check_path
      expect(response.status).to eq(500)
      expect(response.parsed_body["message"]).to eq("Database NOT connected!")
    end
  end
end
