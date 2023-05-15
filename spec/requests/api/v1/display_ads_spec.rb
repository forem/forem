require "rails_helper"

RSpec.describe "Api::V1::DisplayAds" do
  let!(:v1_headers) { { "content-type" => "application/json", "Accept" => "application/vnd.forem.api-v1+json" } }

  let(:organization) { create(:organization) }
  let(:display_ad_params) do
    {
      name: "This is new",
      organization_id: organization.id,
      display_to: "all",
      placement_area: "post_comments",
      body_markdown: "## This ad is a new ad.\n\nYay!",
      type_of: "community",
      published: true,
      approved: true
    }
  end
  let!(:ad1) { create(:display_ad, published: true, approved: true, type_of: "in_house") }

  shared_context "when user is authorized" do
    let(:api_secret) { create(:api_secret) }
    let(:user) { api_secret.user }
    let(:auth_header) { v1_headers.merge({ "api-key" => api_secret.secret }) }
    before { user.add_role(:admin) }
  end

  context "when authenticated and authorized and get to index" do
    include_context "when user is authorized"

    describe "GET /api/display_ads" do
      it "returns json response" do
        get api_display_ads_path, headers: auth_header
        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body.size).to eq(1)
      end
    end

    describe "POST /api/display_ads" do
      it "creates a new display_ad" do
        post api_display_ads_path, params: display_ad_params.to_json, headers: auth_header

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body.keys).to \
          contain_exactly("approved", "body_markdown", "cached_tag_list",
                          "clicks_count", "created_at", "display_to", "id",
                          "impressions_count", "name", "organization_id",
                          "placement_area", "processed_html", "published",
                          "success_rate", "tag_list", "type_of", "updated_at",
                          "creator_id", "exclude_article_ids", "audience_segment_type")
      end

      it "returns a malformed response" do
        post api_display_ads_path, params: display_ad_params.merge(display_to: "steve").to_json, headers: auth_header

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body.keys).to contain_exactly("error")
      end
    end

    describe "GET /api/display_ads/:id" do
      it "returns json response" do
        get api_display_ad_path(ad1.id), headers: auth_header

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("application/json")
        expect(response.parsed_body).to include(
          "id" => ad1.id,
          "published" => true,
          "approved" => true,
          "type_of" => "in_house",
          "cached_tag_list" => "",
          "clicks_count" => 0,
        )
      end
    end

    describe "PUT /api/display_ads/:id" do
      it "updates an existing display_ad" do
        put api_display_ad_path(ad1.id),
            params: display_ad_params.merge(name: "Updated!", type_of: "external").to_json,
            headers: auth_header

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq("application/json")
        ad1.reload
        expect(ad1.name).to eq("Updated!")
        expect(ad1.type_of).to eq("external")
        expect(response.parsed_body.keys).to \
          contain_exactly("approved", "body_markdown", "cached_tag_list",
                          "clicks_count", "created_at", "display_to", "id",
                          "impressions_count", "name", "organization_id",
                          "placement_area", "processed_html", "published",
                          "success_rate", "tag_list", "type_of", "updated_at",
                          "creator_id", "exclude_article_ids", "audience_segment_type")
      end
    end

    describe "PUT /api/display_ads/:id/unpublish" do
      it "unpublishes the display_ad" do
        put unpublish_api_display_ad_path(ad1.id), headers: auth_header

        expect(response).to have_http_status(:success)
        expect(ad1.reload).not_to be_published
      end
    end
  end

  context "when unauthenticated and get to index" do
    it "returns unauthorized" do
      get api_display_ads_path, headers: v1_headers
      expect(response).to have_http_status(:unauthorized)
    end
  end

  context "when unauthorized and get to show" do
    it "returns unauthorized" do
      get api_display_ads_path, params: { id: ad1.id },
                                headers: v1_headers.merge({ "api-key" => "invalid api key" })
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
