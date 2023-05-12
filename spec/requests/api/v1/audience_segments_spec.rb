require "rails_helper"

RSpec.describe "Api::V1::AudienceSegments" do
  let(:v1_headers) { { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json" } }

  let(:api_secret) { create(:api_secret) }
  let(:admin) { api_secret.user }
  let(:headers) { v1_headers.merge({ "api-key" => api_secret.secret }) }

  before do
    admin.add_role(:admin)
  end

  shared_examples "an admin-only protected resource" do
    context "when no API secret is provided" do
      let(:headers) { v1_headers }

      it "returns unauthorized" do
        make_request
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when the authenticated user is not an admin" do
      let(:regular_api_secret) { create(:api_secret) }
      let(:headers) { v1_headers.merge({ "api-key" => regular_api_secret.secret }) }

      it "returns unauthorized" do
        make_request
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/segments" do
    it_behaves_like "an admin-only protected resource" do
      subject(:make_request) { post api_segments_path, headers: headers }
    end

    context "when authenticated and authorized" do
      it "creates a new manual audience segment" do
        post api_segments_path, headers: headers

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("application/json")

        segment = AudienceSegment.last
        expect(segment.manual?).to be(true)
        expect(response.parsed_body).to include(
          "id" => segment.id,
          "type_of" => "manual",
        )
      end
    end
  end
end
