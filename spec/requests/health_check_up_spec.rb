require "rails_helper"

RSpec.describe "HealthCheckUp" do
  describe "GET /up" do
    it "returns 200 OK without authentication or Subforem database lookups" do
      allow(Subforem).to receive(:cached_default_id)

      get "/up"

      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to eq("no-store")
      expect(Subforem).not_to have_received(:cached_default_id)
    end

    it "succeeds on HEAD /up" do
      head "/up"

      expect(response).to have_http_status(:ok)
      expect(response.body).to be_empty
    end

    it "reserves 'up' in ReservedWords and maps rails_health_check_path" do
      expect(rails_health_check_path).to eq("/up")
      expect(ReservedWords.all).to include("up")
    end
  end
end
