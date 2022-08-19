require "rails_helper"

# Subclass of v0::ApiController for testing
module Api
  module V0
    class TestsController < ApiController
      def index; end
    end
  end
end

RSpec.describe "Api::V0::ApiController", type: :request do
  let(:path) { "/api/tests" }

  before do
    # Dynamically add a route to our testing V0::ApiController subclass
    Rails.application.routes.draw do
      namespace :api, defaults: { format: "json" } do
        scope module: :v0 do
          resources :tests
        end
      end
    end
  end

  after do
    # Clean up the route we added!
    Rails.application.reload_routes!
  end

  context "when API V1 is enabled" do
    before { allow(FeatureFlag).to receive(:enabled?).and_return(true) }

    context "when request header is v0 and does not include an api key" do
      let(:headers) { { Accept: "application/v0+json" } }

      it "responds with a Warning header with code 299" do
        get path, headers: headers

        expect(response).to have_http_status(:success)
        # rubocop:disable Layout/LineLength
        expect(response.headers["Warning"])
          .to eq("299 - This endpoint will require the `api-key` header and the `Accept` header to be set to `application/vnd.forem.api-v1+json` in future.")
        # rubocop:enable Layout/LineLength
      end
    end

    context "when request header is v0 and includes an empty api key" do
      let(:headers) { { Accept: "application/v0+json", "api-key": nil } }

      it "responds with a Warning header with code 299" do
        get path, headers: headers

        expect(response).to have_http_status(:success)
        # rubocop:disable Layout/LineLength
        expect(response.headers["Warning"])
          .to eq("299 - This endpoint will require the `api-key` header and the `Accept` header to be set to `application/vnd.forem.api-v1+json` in future.")
        # rubocop:enable Layout/LineLength
      end
    end

    context "when request header is v0 and includes an api key" do
      let(:headers) { { Accept: "application/v0+json", "api-key": "abc123" } }

      it "responds with a Warning header with code 299" do
        get path, headers: headers

        expect(response).to have_http_status(:success)
        # rubocop:disable Layout/LineLength
        expect(response.headers["Warning"])
          .to eq("299 - This endpoint will require the `api-key` header and the `Accept` header to be set to `application/vnd.forem.api-v1+json` in future.")
        # rubocop:enable Layout/LineLength
      end
    end

    context "when request header is missing" do
      let(:headers) { {} }

      it "responds with a Success code and no warning header" do
        get path, headers: headers

        expect(response).to have_http_status(:success)
        # rubocop:disable Layout/LineLength
        expect(response.headers["Warning"])
          .to eq("299 - This endpoint will require the `api-key` header and the `Accept` header to be set to `application/vnd.forem.api-v1+json` in future.")
        # rubocop:enable Layout/LineLength
      end
    end
  end

  context "when API V1 is NOT enabled" do
    before do
      allow(FeatureFlag).to receive(:enabled?).with(:api_v1).and_return(false)
    end

    context "when request header is v0" do
      let(:headers) { { Accept: "application/v0+json" } }

      it "responds with a Success code and no warning header" do
        get path, headers: headers

        expect(response).to have_http_status(:success)
        expect(response.headers["Warning"]).to be_nil
      end
    end

    context "when request header is missing" do
      let(:headers) { {} }

      it "responds with a Success code and no warning header" do
        get path, headers: headers

        expect(response).to have_http_status(:success)
        expect(response.headers["Warning"]).to be_nil
      end
    end
  end
end
