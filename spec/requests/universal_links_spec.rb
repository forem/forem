require "rails_helper"

RSpec.describe "Universal Links (Apple)", type: :request do
  let(:aasa_route) { "/.well-known/apple-app-site-association" }
  let(:forem_app_id) { "R9SWHSQNV8.com.forem.app" }

  describe "returns a valid Apple App Site Association file" do
    context "with multiple ConsumerApps" do
      it "responds with applinks support for iOS apps only" do
        # This iOS ConsumerApp should appear in the results
        ios_app = create(:consumer_app, platform: Device::IOS)
        # This Android ConsumerApp shouldn't appear in the results
        create(:consumer_app, platform: Device::ANDROID)

        get aasa_route
        json_response = JSON.parse(response.body)

        both_app_ids = [forem_app_id, ios_app.app_bundle]
        expect(response).to have_http_status(:ok)
        expect(json_response.dig("applinks", "apps")).to be_empty
        json_response.dig("applinks", "details").each do |hash|
          expect(both_app_ids).to include(hash["appID"])
          expect(hash["paths"]).to match_array(["/*"])
        end
      end
    end

    context "without any custom ConsumerApps" do
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
