require "rails_helper"

RSpec.describe "Api::V1::Billboards" do
  let!(:v1_headers) { { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json" } }

  let(:organization) { create(:organization) }
  let(:billboard_params) do
    {
      name: "This is new",
      organization_id: organization.id,
      display_to: "all",
      placement_area: "post_comments",
      body_markdown: "## This ad is a new ad.\n\nYay!",
      type_of: "community",
      published: true,
      approved: true,
      target_geolocations: "US-WA, CA-BC"
    }
  end
  let!(:billboard1) { create(:billboard, published: true, approved: true, type_of: "in_house") }

  shared_context "when user is authorized" do
    let(:api_secret) { create(:api_secret) }
    let(:user) { api_secret.user }
    let(:auth_header) { v1_headers.merge({ "api-key" => api_secret.secret }) }
    before { user.add_role(:admin) }
  end

  context "when authenticated and authorized and get to index" do
    include_context "when user is authorized"

    describe "GET /api/billboards" do
      it "returns json response" do
        get api_billboards_path, headers: auth_header
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body.size).to eq(1)
      end
    end

    describe "POST /api/billboards" do
      it "creates a new billboard" do
        post api_billboards_path, params: billboard_params.to_json, headers: auth_header

        expect(response).to have_http_status(:created)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body.keys).to \
          contain_exactly("approved", "body_markdown", "cached_tag_list",
                          "clicks_count", "created_at", "display_to", "id",
                          "impressions_count", "name", "organization_id",
                          "placement_area", "processed_html", "published",
                          "success_rate", "tag_list", "type_of", "updated_at",
                          "creator_id", "exclude_article_ids",
                          "audience_segment_type", "audience_segment_id",
                          "priority", "weight", "target_geolocations",
                          "render_mode", "template")
        expect(response.parsed_body["target_geolocations"]).to contain_exactly("US-WA", "CA-BC")
      end

      it "also accepts target geolocations as an array" do
        post api_billboards_path,
             params: billboard_params.merge(target_geolocations: %w[US-WA CA-BC]).to_json,
             headers: auth_header

        expect(response).to have_http_status(:created)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body.keys).to \
          contain_exactly("approved", "body_markdown", "cached_tag_list",
                          "clicks_count", "created_at", "display_to", "id",
                          "impressions_count", "name", "organization_id",
                          "placement_area", "processed_html", "published",
                          "success_rate", "tag_list", "type_of", "updated_at",
                          "creator_id", "exclude_article_ids",
                          "audience_segment_type", "audience_segment_id",
                          "priority", "weight", "target_geolocations",
                          "render_mode", "template")
        expect(response.parsed_body["target_geolocations"]).to contain_exactly("US-WA", "CA-BC")
      end

      it "returns a malformed response with invalid display_to" do
        post api_billboards_path, params: billboard_params.merge(display_to: "steve").to_json, headers: auth_header

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body.keys).to contain_exactly("error", "status")
        expect(response.parsed_body["error"]).to include("'steve' is not a valid display_to")
      end

      it "returns a malformed response with invalid geolocation" do
        expect do
          post api_billboards_path,
               params: billboard_params.merge(target_geolocations: "US-FAKE").to_json,
               headers: auth_header
        end.not_to change(Billboard, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body.keys).to contain_exactly("error", "status")
        expect(response.parsed_body["error"]).to include("US-FAKE is not an enabled target ISO 3166-2 code")
      end
    end

    describe "GET /api/billboards/:id" do
      it "returns json response" do
        get api_billboard_path(billboard1.id), headers: auth_header

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body).to include(
          "id" => billboard1.id,
          "published" => true,
          "approved" => true,
          "priority" => false,
          "weight" => 1.0,
          "type_of" => "in_house",
          "cached_tag_list" => "",
          "clicks_count" => 0,
        )
      end
    end

    describe "PUT /api/billboards/:id" do
      it "updates an existing billboard" do
        put api_billboard_path(billboard1.id),
            params: billboard_params.merge(name: "Updated!", type_of: "external").to_json,
            headers: auth_header

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("application/json")
        billboard1.reload
        expect(billboard1.name).to eq("Updated!")
        expect(billboard1.type_of).to eq("external")
        expect(response.parsed_body.keys).to \
          contain_exactly("approved", "body_markdown", "cached_tag_list",
                          "clicks_count", "created_at", "display_to", "id",
                          "impressions_count", "name", "organization_id",
                          "placement_area", "processed_html", "published",
                          "success_rate", "tag_list", "type_of", "updated_at",
                          "creator_id", "exclude_article_ids",
                          "audience_segment_type", "audience_segment_id",
                          "priority", "weight", "target_geolocations",
                          "render_mode", "template")
      end

      it "also accepts target geolocations as an array" do
        put api_billboard_path(billboard1.id), params: { target_geolocations: %w[US-FL US-GA] }.to_json,
                                               headers: auth_header

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("application/json")
        billboard1.reload
        expect(billboard1.target_geolocations).to contain_exactly(
          Geolocation.from_iso3166("US-FL"),
          Geolocation.from_iso3166("US-GA"),
        )
      end

      it "returns a malformed response with invalid geolocation" do
        put api_billboard_path(billboard1.id), params: { target_geolocations: "US-FAKE" }.to_json, headers: auth_header

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body.keys).to contain_exactly("error", "status")
        expect(response.parsed_body["error"]).to include("US-FAKE is not an enabled target ISO 3166-2 code")
      end
    end

    describe "PUT /api/billboards/:id/unpublish" do
      it "unpublishes the billboard" do
        put unpublish_api_billboard_path(billboard1.id), headers: auth_header

        expect(response).to have_http_status(:success)
        expect(billboard1.reload).not_to be_published
      end
    end
  end

  context "when unauthenticated and get to index" do
    it "returns unauthorized" do
      get api_billboards_path, headers: v1_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when unauthorized and get to show" do
    it "returns unauthorized" do
      get api_billboards_path, params: { id: billboard1.id },
                               headers: v1_headers.merge({ "api-key" => "invalid api key" })
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
