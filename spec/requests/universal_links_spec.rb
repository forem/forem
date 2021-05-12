require "rails_helper"

RSpec.describe "Universal Links (Apple)", type: :request do
  let(:aasa_route) { "/.well-known/apple-app-site-association" }
  let(:forem_app_id) { "R9SWHSQNV8.com.forem.app" }
  let(:dev_app_id) { "R9SWHSQNV8.to.dev.ios" }

  describe "returns a valid Apple App Site Association file" do
    context "with DEV app backwards compatibility" do
      it "responds with applinks support for both" do
        allow(SiteConfig).to receive(:dev_to?).and_return(true)
        get aasa_route
        json_response = JSON.parse(response.body)

        both_app_ids = [forem_app_id, dev_app_id]
        expect(response).to have_http_status(:ok)
        expect(json_response.dig("applinks", "apps")).to be_empty
        json_response.dig("applinks", "details").each do |hash|
          expect(both_app_ids).to include(hash["appID"])
          expect(hash["paths"]).to match_array(["/*"])
        end
      end
    end

    context "when non-DEV Forem instance" do
      it "responds with applinks support for Forem app" do
        get aasa_route
        json_response = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)

        expect(json_response.dig("applinks", "apps")).to be_empty
        json_response.dig("applinks", "details").each do |hash|
          expect(hash["appID"]).to eq(forem_app_id)
          expect(hash["paths"]).to match_array(["/*"])
        end
      end
    end

    context "when non-public Forem instance" do
      it "responds with applinks support for Forem app", :aggregate_failures do
        allow(Settings::UserExperience).to receive(:public).and_return(false)
        get aasa_route
        json_response = JSON.parse(response.body)
        expect(response).to have_http_status(:ok)

        expect(json_response.dig("applinks", "apps")).to be_empty
        json_response.dig("applinks", "details").each do |hash|
          expect(hash["appID"]).to eq(forem_app_id)
          expect(hash["paths"]).to match_array(["/*"])
        end
      end
    end
  end
end
